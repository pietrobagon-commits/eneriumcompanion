//
//  VoiceRecognitionViewModel.swift
//  CommanderScorekeeper
//
//  Main ViewModel orchestrating voice recognition flow.
//  Integrates wake word detection, speaker ID, NLP parsing, and TTS.
//

import Foundation
import Combine
import SwiftUI

/// Voice recognition orchestrator ViewModel
@MainActor
final class VoiceRecognitionViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Voice recognition service
    @Published var voiceService: VoiceRecognitionService

    /// Speaker identification service
    @Published var speakerService: SpeakerIdentificationService

    /// Text-to-speech service
    @Published var ttsService: TextToSpeechService

    /// Is voice recognition active
    @Published var isActive: Bool = false

    /// Is currently listening (wake word or command)
    @Published var isListening: Bool = false

    /// Current state message for UI
    @Published var statusMessage: String = ""

    /// Show speaker selection popup
    @Published var showSpeakerSelection: Bool = false

    /// Last recognized command (for speaker selection)
    @Published var pendingCommand: ParsedCommand?

    /// Recognized speaker (for UI feedback)
    @Published var recognizedSpeaker: String?

    // MARK: - Dependencies

    private let gameViewModel: GameViewModel
    private var nlpParser: NLPCommandParser?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(gameViewModel: GameViewModel) {
        self.gameViewModel = gameViewModel
        self.voiceService = VoiceRecognitionService()
        self.speakerService = SpeakerIdentificationService()
        self.ttsService = TextToSpeechService()

        setupBindings()
        setupVoiceCallbacks()

        #if DEBUG
        print("🎤 VoiceRecognitionViewModel initialized")
        #endif
    }

    // MARK: - Setup

    private func setupBindings() {
        // Bind voice service listening state to local state
        voiceService.$isListening
            .sink { [weak self] isListening in
                self?.isListening = isListening
            }
            .store(in: &cancellables)

        // Bind voice service state to status message
        voiceService.$state
            .sink { [weak self] state in
                self?.updateStatusMessage(for: state)
            }
            .store(in: &cancellables)
    }

    private func setupVoiceCallbacks() {
        // Wake word detected
        voiceService.onWakeWordDetected = { [weak self] in
            Task { @MainActor in
                self?.handleWakeWordDetected()
            }
        }

        // Command recognized
        voiceService.onCommandRecognized = { [weak self] text, confidence in
            Task { @MainActor in
                await self?.handleCommandRecognized(text: text, confidence: confidence)
            }
        }

        // Error occurred
        voiceService.onError = { [weak self] error in
            Task { @MainActor in
                self?.handleVoiceError(error)
            }
        }
    }

    // MARK: - Voice Control

    /// Start voice recognition
    func startVoiceRecognition() async {
        guard !isActive else { return }

        do {
            // Load voice profiles
            speakerService.loadProfiles(from: gameViewModel.players)

            // Create NLP parser with current players
            let playerNames = gameViewModel.players.map { $0.name }
            let commanders = gameViewModel.players.reduce(into: [String: String]()) { dict, player in
                dict[player.name] = player.commanderName
            }
            nlpParser = NLPCommandParser(playerNames: playerNames, commanders: commanders)

            // Start wake word detection
            try await voiceService.startWakeWordDetection()

            isActive = true
            statusMessage = "In ascolto per 'Hey Commander'..."

            // Welcome message
            ttsService.speakMessage("Riconoscimento vocale attivato", priority: .high)

            HapticManager.shared.success()

            #if DEBUG
            print("✅ Voice recognition started")
            #endif

        } catch {
            #if DEBUG
            print("❌ Failed to start voice recognition: \(error)")
            #endif

            statusMessage = "Errore: \(error.localizedDescription)"
            ttsService.speakError("Impossibile avviare riconoscimento vocale")
            HapticManager.shared.error()
        }
    }

    /// Stop voice recognition
    func stopVoiceRecognition() {
        voiceService.stopWakeWordDetection()
        voiceService.stopCommandRecognition()
        ttsService.stopSpeaking()

        isActive = false
        isListening = false
        statusMessage = "Riconoscimento vocale disattivato"

        HapticManager.shared.medium()

        #if DEBUG
        print("🛑 Voice recognition stopped")
        #endif
    }

    /// Toggle voice recognition on/off
    func toggleVoiceRecognition() async {
        if isActive {
            stopVoiceRecognition()
        } else {
            await startVoiceRecognition()
        }
    }

    // MARK: - Wake Word Handling

    private func handleWakeWordDetected() {
        statusMessage = "Comando in ascolto..."

        // Play wake word sound (ding)
        ttsService.speakWakeWordDetected()

        // Visual feedback
        HapticManager.shared.selection()

        #if DEBUG
        print("👂 Wake word detected, listening for command...")
        #endif
    }

    // MARK: - Command Recognition Handling

    private func handleCommandRecognized(text: String, confidence: Float) async {
        statusMessage = "Elaborazione comando..."

        #if DEBUG
        print("🗣️ Command: '\(text)' (confidence: \(String(format: "%.2f", confidence)))")
        #endif

        // Parse command with NLP
        guard let nlpParser = nlpParser,
              let parsedCommand = nlpParser.parse(command: text) else {
            #if DEBUG
            print("❌ Failed to parse command")
            #endif

            statusMessage = "Comando non riconosciuto"
            ttsService.speakCommandNotUnderstood()
            HapticManager.shared.error()
            return
        }

        #if DEBUG
        print("✅ Parsed: \(parsedCommand.description)")
        #endif

        // Identify speaker
        await identifySpeakerAndExecute(command: parsedCommand, audioText: text)
    }

    // MARK: - Speaker Identification

    private func identifySpeakerAndExecute(command: ParsedCommand, audioText: String) async {
        // For now, we'll use a simplified approach
        // In a real implementation, you would capture audio data during recognition

        // Try to identify from command text (if player name is mentioned)
        if let actorName = command.actor, actorName != "io" {
            // Find player by name
            if let player = findPlayer(byName: actorName) {
                executeCommand(command, for: player)
                return
            }
        }

        // Otherwise, show speaker selection
        showSpeakerSelectionPopup(for: command)
    }

    private func showSpeakerSelectionPopup(for command: ParsedCommand) {
        pendingCommand = command
        showSpeakerSelection = true
        statusMessage = "Chi ha parlato?"

        ttsService.speakAskWhoSpoke()

        #if DEBUG
        print("❓ Showing speaker selection")
        #endif
    }

    /// Execute command for a selected speaker
    func executeCommandForSpeaker(_ player: Player) {
        guard let command = pendingCommand else { return }

        showSpeakerSelection = false
        pendingCommand = nil

        executeCommand(command, for: player)
    }

    // MARK: - Command Execution

    private func executeCommand(_ command: ParsedCommand, for speaker: Player) {
        statusMessage = "Esecuzione comando..."

        #if DEBUG
        print("▶️ Executing: \(command.description) for \(speaker.name)")
        #endif

        // Resolve target player
        let targetPlayer: Player?
        if let targetName = command.target {
            targetPlayer = findPlayer(byName: targetName)
        } else {
            targetPlayer = speaker
        }

        guard let target = targetPlayer else {
            #if DEBUG
            print("❌ Target player not found")
            #endif
            statusMessage = "Giocatore non trovato"
            ttsService.speakError("Giocatore non trovato")
            return
        }

        // Execute based on command type
        switch command.type {
        case .lifeChange:
            gameViewModel.changeLife(for: target, amount: command.value)

        case .commanderDamage:
            // Find attacker
            var attacker: Player?
            if let attackerName = command.metadata["attackerName"] {
                attacker = findPlayer(byName: attackerName)
            } else if let commanderName = command.metadata["commanderName"] {
                attacker = findPlayer(byCommander: commanderName)
            }

            if let attacker = attacker {
                gameViewModel.applyCommanderDamage(from: attacker, to: target, amount: command.value)
            } else {
                #if DEBUG
                print("❌ Attacker not found")
                #endif
                ttsService.speakError("Comandante non trovato")
                return
            }

        case .poisonCounter:
            gameViewModel.addPoisonCounters(to: target, amount: command.value)

        case .energyCounter:
            gameViewModel.addEnergyCounters(to: target, amount: command.value)

        case .experienceCounter:
            gameViewModel.addExperienceCounters(to: target, amount: command.value)

        case .monarchChange:
            gameViewModel.setMonarch(target)

        case .initiativeChange:
            gameViewModel.setInitiative(target)

        default:
            #if DEBUG
            print("⚠️ Unhandled command type: \(command.type)")
            #endif
            return
        }

        // Success feedback
        statusMessage = "Comando eseguito"
        ttsService.speakCommandConfirmation(command)
        HapticManager.shared.voiceCommandRecognized()

        recognizedSpeaker = speaker.name

        // Clear after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.recognizedSpeaker = nil
        }
    }

    // MARK: - Error Handling

    private func handleVoiceError(_ error: VoiceRecognitionError) {
        statusMessage = error.localizedDescription
        ttsService.speakError(error.localizedDescription)
        HapticManager.shared.error()

        #if DEBUG
        print("❌ Voice error: \(error)")
        #endif

        // For authorization errors, might want to show settings
        if case .notAuthorized = error {
            // Could trigger settings alert here
        }
    }

    // MARK: - Helpers

    private func updateStatusMessage(for state: VoiceRecognitionState) {
        switch state {
        case .idle:
            statusMessage = isActive ? "In pausa" : "Inattivo"

        case .listeningForWakeWord:
            statusMessage = "In ascolto per 'Hey Commander'..."

        case .listeningForCommand:
            statusMessage = "Comando in ascolto..."

        case .processing:
            statusMessage = "Elaborazione..."

        case .error(let error):
            statusMessage = "Errore: \(error.localizedDescription)"
        }
    }

    private func findPlayer(byName name: String) -> Player? {
        gameViewModel.players.first { player in
            player.name.lowercased() == name.lowercased()
        }
    }

    private func findPlayer(byCommander commanderName: String) -> Player? {
        gameViewModel.players.first { player in
            player.commanderName.lowercased().contains(commanderName.lowercased()) ||
            commanderName.lowercased().contains(player.commanderName.lowercased().split(separator: " ").first ?? "")
        }
    }

    // MARK: - Cleanup

    deinit {
        stopVoiceRecognition()
    }
}

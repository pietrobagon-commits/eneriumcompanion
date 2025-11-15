//
//  TextToSpeechService.swift
//  CommanderScorekeeper
//
//  Text-to-Speech service for voice feedback.
//  Provides audio confirmation of game actions.
//

import Foundation
import AVFoundation

/// Text-to-Speech service
@MainActor
final class TextToSpeechService: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Whether TTS is currently speaking
    @Published var isSpeaking: Bool = false

    /// Whether TTS is enabled
    @Published var isEnabled: Bool = true

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var voiceQueue: [String] = []
    private var isProcessingQueue: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self

        #if DEBUG
        print("🔊 TextToSpeechService initialized")
        #endif
    }

    // MARK: - Speech Methods

    /// Speak text with default settings
    func speak(_ text: String, priority: Priority = .normal) {
        guard isEnabled else { return }

        #if DEBUG
        print("💬 Speaking: \(text)")
        #endif

        switch priority {
        case .immediate:
            // Stop current speech and speak immediately
            stopSpeaking()
            speakNow(text)

        case .high:
            // Insert at front of queue
            voiceQueue.insert(text, at: 0)
            processQueue()

        case .normal:
            // Add to queue
            voiceQueue.append(text)
            processQueue()

        case .low:
            // Add to end of queue only if not too long
            if voiceQueue.count < 5 {
                voiceQueue.append(text)
                processQueue()
            }
        }
    }

    /// Stop current speech
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false

        #if DEBUG
        print("🛑 Stopped speaking")
        #endif
    }

    /// Clear speech queue
    func clearQueue() {
        voiceQueue.removeAll()

        #if DEBUG
        print("🗑️ Cleared speech queue")
        #endif
    }

    /// Enable/disable TTS
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled

        if !enabled {
            stopSpeaking()
            clearQueue()
        }

        #if DEBUG
        print("🔊 TTS \(enabled ? "enabled" : "disabled")")
        #endif
    }

    // MARK: - Command Feedback

    /// Speak confirmation for a game command
    func speakCommandConfirmation(_ command: ParsedCommand) {
        let message: String

        switch command.type {
        case .lifeChange:
            let who = command.actor ?? "Giocatore"
            let verb = command.value > 0 ? "guadagna" : "perde"
            let absValue = abs(command.value)
            let plural = absValue == 1 ? "vita" : "vite"
            message = "Fatto! \(who) \(verb) \(absValue) \(plural)"

        case .commanderDamage:
            let who = command.target ?? "Giocatore"
            let from = command.metadata["commanderName"] ?? "comandante"
            message = "\(command.value) danni da \(from) a \(who)"

        case .poisonCounter:
            let who = command.target ?? "Giocatore"
            let plural = command.value == 1 ? "counter" : "counter"
            message = "\(who) ha \(command.value) poison \(plural)"

        case .energyCounter:
            let who = command.target ?? "Giocatore"
            let verb = command.value > 0 ? "guadagna" : "perde"
            message = "\(who) \(verb) \(abs(command.value)) energy"

        case .experienceCounter:
            let who = command.target ?? "Giocatore"
            message = "\(who) guadagna \(command.value) experience"

        case .monarchChange:
            let who = command.target ?? "Giocatore"
            message = "\(who) è il nuovo Monarch"

        case .initiativeChange:
            let who = command.target ?? "Giocatore"
            message = "\(who) ha l'iniziativa"

        default:
            message = "Comando eseguito"
        }

        speak(message, priority: .high)
    }

    /// Speak error message
    func speakError(_ error: String) {
        speak(error, priority: .high)
    }

    /// Speak generic message
    func speakMessage(_ message: String, priority: Priority = .normal) {
        speak(message, priority: priority)
    }

    // MARK: - Common Messages

    /// Wake word detected
    func speakWakeWordDetected() {
        // Short "ding" sound would be better here, but we can use TTS
        speak("", priority: .immediate) // Silent to stop current speech
    }

    /// Command not understood
    func speakCommandNotUnderstood() {
        speak("Non ho capito, puoi ripetere?", priority: .high)
    }

    /// Timeout
    func speakTimeout() {
        speak("Tempo scaduto", priority: .high)
    }

    /// Ask who spoke
    func speakAskWhoSpoke() {
        speak("Chi ha parlato?", priority: .high)
    }

    /// Player eliminated
    func speakPlayerEliminated(_ playerName: String, reason: String) {
        speak("\(playerName) è stato eliminato: \(reason)", priority: .immediate)
    }

    /// Game started
    func speakGameStarted() {
        speak("Partita iniziata. Buon divertimento!", priority: .high)
    }

    /// Game ended
    func speakGameEnded(winner: String?) {
        if let winner = winner {
            speak("Partita terminata. Vince \(winner)!", priority: .immediate)
        } else {
            speak("Partita terminata", priority: .immediate)
        }
    }

    // MARK: - Priority Enum

    enum Priority {
        case immediate // Stop current and speak now
        case high      // Front of queue
        case normal    // Back of queue
        case low       // Back of queue if not too long
    }

    // MARK: - Private Methods

    private func processQueue() {
        guard !isProcessingQueue, !voiceQueue.isEmpty else { return }

        isProcessingQueue = true
        let text = voiceQueue.removeFirst()
        speakNow(text)
    }

    private func speakNow(_ text: String) {
        guard !text.isEmpty else {
            isProcessingQueue = false
            processQueue()
            return
        }

        let utterance = AVSpeechUtterance(string: text)

        // Configure voice
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = Constants.Voice.ttsRate // Slightly faster
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8

        // Reduce volume during listening to avoid feedback
        if synthesizer.isSpeaking {
            utterance.volume = 0.6
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    private func onFinishedSpeaking() {
        isSpeaking = false
        isProcessingQueue = false

        // Process next item in queue
        if !voiceQueue.isEmpty {
            processQueue()
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onFinishedSpeaking()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onFinishedSpeaking()
        }
    }
}

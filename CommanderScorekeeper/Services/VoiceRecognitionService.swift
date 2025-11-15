//
//  VoiceRecognitionService.swift
//  CommanderScorekeeper
//
//  Voice recognition service using Speech Framework.
//  Handles wake word detection and command recognition.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Voice recognition states
enum VoiceRecognitionState {
    case idle
    case listeningForWakeWord
    case listeningForCommand
    case processing
    case error(Error)
}

/// Voice recognition errors
enum VoiceRecognitionError: LocalizedError {
    case notAuthorized
    case notAvailable
    case audioSessionError
    case recognitionFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Autorizzazione microfono negata. Abilita in Impostazioni."
        case .notAvailable:
            return "Riconoscimento vocale non disponibile."
        case .audioSessionError:
            return "Errore nella sessione audio."
        case .recognitionFailed(let message):
            return "Riconoscimento fallito: \(message)"
        case .timeout:
            return "Timeout riconoscimento vocale."
        }
    }
}

/// Voice recognition service managing wake word and command detection
@MainActor
final class VoiceRecognitionService: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Current recognition state
    @Published var state: VoiceRecognitionState = .idle

    /// Last recognized text
    @Published var recognizedText: String = ""

    /// Confidence score (0.0-1.0)
    @Published var confidence: Float = 0.0

    /// Is currently listening
    @Published var isListening: Bool = false

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var wakeWords: [String] = Constants.Voice.wakeWords
    private var commandTimeoutTimer: Timer?

    private var cancellables = Set<AnyCancellable>()

    // Callbacks
    var onWakeWordDetected: (() -> Void)?
    var onCommandRecognized: ((String, Float) -> Void)?
    var onError: ((VoiceRecognitionError) -> Void)?

    // MARK: - Initialization

    override init() {
        // Initialize with Italian locale
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "it_IT"))
        super.init()

        speechRecognizer?.delegate = self

        #if DEBUG
        print("🎤 VoiceRecognitionService initialized with locale: \(speechRecognizer?.locale.identifier ?? "unknown")")
        #endif
    }

    // MARK: - Authorization

    /// Request microphone and speech recognition authorization
    func requestAuthorization() async -> Bool {
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            await MainActor.run {
                state = .error(.notAuthorized)
                onError?(.notAuthorized)
            }
            return false
        }

        // Request microphone permission
        let audioStatus = await AVAudioSession.sharedInstance().requestRecordPermission()

        guard audioStatus else {
            await MainActor.run {
                state = .error(.notAuthorized)
                onError?(.notAuthorized)
            }
            return false
        }

        #if DEBUG
        print("✅ Voice recognition authorized")
        #endif

        return true
    }

    // MARK: - Wake Word Detection

    /// Start listening for wake word in low-power mode
    func startWakeWordDetection() async throws {
        guard await requestAuthorization() else {
            throw VoiceRecognitionError.notAuthorized
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceRecognitionError.notAvailable
        }

        try startAudioEngine(mode: .wakeWord)

        state = .listeningForWakeWord
        isListening = true

        #if DEBUG
        print("👂 Listening for wake word: \(wakeWords.joined(separator: ", "))")
        #endif
    }

    /// Stop wake word detection
    func stopWakeWordDetection() {
        stopAudioEngine()
        state = .idle
        isListening = false

        #if DEBUG
        print("🛑 Wake word detection stopped")
        #endif
    }

    // MARK: - Command Recognition

    /// Start listening for a command (after wake word)
    func startCommandRecognition(timeout: TimeInterval = Constants.Voice.wakeWordTimeout) async throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceRecognitionError.notAvailable
        }

        // Stop any existing recognition
        stopAudioEngine()

        // Start fresh for command
        try startAudioEngine(mode: .command)

        state = .listeningForCommand
        isListening = true

        // Set timeout
        commandTimeoutTimer?.invalidate()
        commandTimeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleCommandTimeout()
            }
        }

        #if DEBUG
        print("🎯 Listening for command (timeout: \(timeout)s)")
        #endif
    }

    /// Stop command recognition
    func stopCommandRecognition() {
        commandTimeoutTimer?.invalidate()
        commandTimeoutTimer = nil

        stopAudioEngine()
        state = .idle
        isListening = false

        #if DEBUG
        print("🛑 Command recognition stopped")
        #endif
    }

    // MARK: - Audio Engine

    private enum RecognitionMode {
        case wakeWord
        case command
    }

    private func startAudioEngine(mode: RecognitionMode) throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw VoiceRecognitionError.audioSessionError
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false // Use server for better accuracy

        // Get audio input node
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result, error: error, mode: mode)
            }
        }

        // Install tap on audio
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start engine
        audioEngine.prepare()
        try audioEngine.start()

        #if DEBUG
        print("▶️ Audio engine started in \(mode) mode")
        #endif
    }

    private func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        #if DEBUG
        print("⏹️ Audio engine stopped")
        #endif
    }

    // MARK: - Recognition Result Handling

    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?, mode: RecognitionMode) {
        if let error = error {
            #if DEBUG
            print("❌ Recognition error: \(error.localizedDescription)")
            #endif

            state = .error(.recognitionFailed(error.localizedDescription))
            onError?(.recognitionFailed(error.localizedDescription))
            stopAudioEngine()
            return
        }

        guard let result = result else { return }

        let transcription = result.bestTranscription.formattedString.lowercased()
        let confidence = result.bestTranscription.segments.last?.confidence ?? 0.0

        recognizedText = transcription
        self.confidence = confidence

        #if DEBUG
        print("🗣️ Recognized: '\(transcription)' (confidence: \(String(format: "%.2f", confidence)))")
        #endif

        switch mode {
        case .wakeWord:
            handleWakeWordResult(transcription: transcription)

        case .command:
            if result.isFinal {
                handleCommandResult(transcription: transcription, confidence: confidence)
            }
        }
    }

    private func handleWakeWordResult(transcription: String) {
        // Check if any wake word is detected
        for wakeWord in wakeWords {
            if transcription.contains(wakeWord.lowercased()) {
                #if DEBUG
                print("✅ Wake word detected: '\(wakeWord)'")
                #endif

                // Stop wake word detection
                stopWakeWordDetection()

                // Notify
                onWakeWordDetected?()

                // Automatically start command recognition
                Task {
                    do {
                        try await startCommandRecognition()
                    } catch {
                        #if DEBUG
                        print("❌ Failed to start command recognition: \(error)")
                        #endif
                    }
                }

                return
            }
        }
    }

    private func handleCommandResult(transcription: String, confidence: Float) {
        state = .processing

        // Stop command recognition
        stopCommandRecognition()

        // Notify with command
        onCommandRecognized?(transcription, confidence)

        // Return to wake word listening
        Task {
            do {
                try await startWakeWordDetection()
            } catch {
                #if DEBUG
                print("❌ Failed to restart wake word detection: \(error)")
                #endif
            }
        }
    }

    private func handleCommandTimeout() {
        #if DEBUG
        print("⏱️ Command recognition timeout")
        #endif

        state = .error(.timeout)
        onError?(.timeout)

        stopCommandRecognition()

        // Return to wake word listening
        Task {
            do {
                try await startWakeWordDetection()
            } catch {
                #if DEBUG
                print("❌ Failed to restart wake word detection: \(error)")
                #endif
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceRecognitionService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                state = .error(.notAvailable)
                onError?(.notAvailable)
                stopAudioEngine()

                #if DEBUG
                print("⚠️ Speech recognizer became unavailable")
                #endif
            } else {
                #if DEBUG
                print("✅ Speech recognizer became available")
                #endif
            }
        }
    }
}

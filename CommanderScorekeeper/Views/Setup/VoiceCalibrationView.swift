//
//  VoiceCalibrationView.swift
//  CommanderScorekeeper
//
//  Voice calibration view for player setup.
//  Records 3 voice samples for speaker identification.
//

import SwiftUI
import AVFoundation

struct VoiceCalibrationView: View {

    // MARK: - Properties

    let playerConfig: PlayerConfiguration
    let playerIndex: Int

    @ObservedObject var speakerService: SpeakerIdentificationService

    @State private var isRecording = false
    @State private var recordingProgress: Int = 0
    @State private var showError = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss

    private var isComplete: Bool {
        recordingProgress >= Constants.Voice.calibrationRepetitions
    }

    private var currentSample: Int {
        recordingProgress + 1
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Constants.Layout.largePadding) {
            // Header
            headerSection

            Spacer()

            // Progress
            progressSection

            // Recording button
            recordingButton

            // Instructions
            instructionsSection

            Spacer()

            // Done button
            if isComplete {
                doneButton
            }
        }
        .padding(Constants.Layout.largePadding)
        .background(Constants.Colors.backgroundPrimary)
        .alert("Errore", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.magicGold)

            Text("Calibrazione Voce")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)

            Text(playerConfig.name)
                .font(.title3)
                .foregroundColor(Constants.Colors.textSecondary)
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress circles
            HStack(spacing: 20) {
                ForEach(0..<Constants.Voice.calibrationRepetitions, id: \.self) { index in
                    ProgressCircle(
                        number: index + 1,
                        isCompleted: index < recordingProgress,
                        isCurrent: index == recordingProgress
                    )
                }
            }

            // Status text
            if isComplete {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Constants.Colors.success)
                    Text("Calibrazione completata!")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.success)
                }
            } else {
                Text("Campione \(currentSample) di \(Constants.Voice.calibrationRepetitions)")
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textSecondary)
            }
        }
    }

    // MARK: - Recording Button

    private var recordingButton: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        isRecording
                            ? Constants.Colors.lifeLoss
                            : Constants.Colors.magicGold
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: (isRecording ? Constants.Colors.lifeLoss : Constants.Colors.magicGold).opacity(0.5), radius: 20)

                if isRecording {
                    // Recording animation
                    Circle()
                        .stroke(Constants.Colors.lifeLoss, lineWidth: 4)
                        .frame(width: 140, height: 140)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .opacity(isRecording ? 0.0 : 1.0)
                        .animation(
                            Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: isRecording
                        )
                }

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.black)
            }
        }
        .disabled(isComplete)
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(spacing: 12) {
            Text(isRecording ? "Pronuncia il tuo nome" : "Tap per registrare")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textPrimary)

            if !isRecording && !isComplete {
                Text("Registra 3 campioni vocali pronunciando il tuo nome chiaramente")
                    .font(.body)
                    .foregroundColor(Constants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Completato")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Constants.Colors.success)
            .foregroundColor(.white)
            .cornerRadius(Constants.Layout.cornerRadius)
        }
    }

    // MARK: - Recording Logic

    private func startRecording() {
        isRecording = true
        HapticManager.shared.medium()

        // Simulate recording for 2 seconds
        // In real implementation, this would use AVAudioRecorder
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            stopRecording()
        }

        #if DEBUG
        print("🎤 Started recording sample \(currentSample)")
        #endif
    }

    private func stopRecording() {
        isRecording = false

        // Create mock audio data for calibration
        // In real implementation, this would be actual audio data from AVAudioRecorder
        let mockAudioData = createMockAudioData()

        Task {
            do {
                // Record sample
                let playerID = UUID() // In real implementation, use actual player ID
                _ = try await speakerService.recordCalibrationSample(
                    for: playerID,
                    audioData: mockAudioData
                )

                // Update progress
                await MainActor.run {
                    recordingProgress += 1
                    HapticManager.shared.success()

                    #if DEBUG
                    print("✅ Recorded sample \(recordingProgress)/\(Constants.Voice.calibrationRepetitions)")
                    #endif
                }

            } catch {
                await MainActor.run {
                    errorMessage = "Errore nella registrazione: \(error.localizedDescription)"
                    showError = true
                    HapticManager.shared.error()
                }

                #if DEBUG
                print("❌ Recording error: \(error)")
                #endif
            }
        }
    }

    private func createMockAudioData() -> Data {
        // Create mock audio data with some random samples
        // In real implementation, this would be actual audio buffer
        var samples: [Int16] = []
        for _ in 0..<44100 { // 1 second at 44.1kHz
            let sample = Int16.random(in: -1000...1000)
            samples.append(sample)
        }

        return Data(bytes: samples, count: samples.count * MemoryLayout<Int16>.size)
    }
}

// MARK: - Progress Circle

struct ProgressCircle: View {
    let number: Int
    let isCompleted: Bool
    let isCurrent: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 60, height: 60)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("\(number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
            }
        }
        .overlay(
            Circle()
                .strokeBorder(borderColor, lineWidth: isCurrent ? 3 : 1)
                .frame(width: 60, height: 60)
        )
        .scaleEffect(isCurrent ? 1.1 : 1.0)
        .animation(.spring(), value: isCurrent)
    }

    private var backgroundColor: Color {
        if isCompleted {
            return Constants.Colors.success
        } else if isCurrent {
            return Constants.Colors.magicGold.opacity(0.2)
        } else {
            return Constants.Colors.backgroundSecondary
        }
    }

    private var borderColor: Color {
        if isCompleted || isCurrent {
            return Constants.Colors.magicGold
        } else {
            return Constants.Colors.textDisabled
        }
    }

    private var textColor: Color {
        isCurrent ? Constants.Colors.magicGold : Constants.Colors.textDisabled
    }
}

// MARK: - Preview

#Preview {
    VoiceCalibrationView(
        playerConfig: PlayerConfiguration(
            name: "Alice",
            commanderName: "Atraxa, Praetors' Voice",
            colorIdentity: ["W", "U", "B", "G"]
        ),
        playerIndex: 0,
        speakerService: SpeakerIdentificationService()
    )
    .preferredColorScheme(.dark)
}

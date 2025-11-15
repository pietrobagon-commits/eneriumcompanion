//
//  VoiceIndicator.swift
//  CommanderScorekeeper
//
//  Voice recognition indicator component.
//  Shows microphone status with visual feedback.
//

import SwiftUI

struct VoiceIndicator: View {

    // MARK: - Properties

    @ObservedObject var voiceViewModel: VoiceRecognitionViewModel

    @State private var pulseAnimation = false

    private var indicatorColor: Color {
        if voiceViewModel.isListening {
            return .blue
        } else if voiceViewModel.isActive {
            return Constants.Colors.textSecondary
        } else {
            return Constants.Colors.textDisabled
        }
    }

    private var iconName: String {
        if voiceViewModel.isListening {
            return "mic.fill"
        } else if voiceViewModel.isActive {
            return "mic"
        } else {
            return "mic.slash"
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Microphone icon with animation
            ZStack {
                // Pulse effect when listening
                if voiceViewModel.isListening {
                    Circle()
                        .fill(indicatorColor.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 1.0)
                        .animation(
                            Animation.easeOut(duration: 1.0)
                                .repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }

                // Icon
                Circle()
                    .fill(indicatorColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(indicatorColor)
            }

            // Status text (optional)
            if !voiceViewModel.statusMessage.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(voiceViewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                        .lineLimit(1)

                    // Recognized speaker
                    if let speaker = voiceViewModel.recognizedSpeaker {
                        Text("Speaker: \(speaker)")
                            .font(.caption2)
                            .foregroundColor(Constants.Colors.magicGold)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Constants.Colors.backgroundSecondary.opacity(0.9))
        .cornerRadius(Constants.Layout.smallCornerRadius)
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Preview

#Preview {
    let gameViewModel = GameViewModel(
        session: PersistenceController.preview.fetchActiveSessions().first!
    )
    let voiceViewModel = VoiceRecognitionViewModel(gameViewModel: gameViewModel)

    return VStack(spacing: 20) {
        VoiceIndicator(voiceViewModel: voiceViewModel)

        Button("Toggle Listening") {
            voiceViewModel.isListening.toggle()
        }
    }
    .padding()
    .background(Constants.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}

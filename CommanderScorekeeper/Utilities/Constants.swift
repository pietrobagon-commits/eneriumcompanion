//
//  Constants.swift
//  CommanderScorekeeper
//
//  Global constants and configuration values.
//

import SwiftUI

/// Global constants for the application
enum Constants {

    // MARK: - Game Rules

    enum GameRules {
        /// Starting life total in Commander
        static let startingLife: Int = 40

        /// Lethal commander damage from a single source
        static let lethalCommanderDamage: Int = 21

        /// Lethal poison counters
        static let lethalPoison: Int = 10

        /// Number of players in Commander
        static let numberOfPlayers: Int = 4
    }

    // MARK: - UI Layout

    enum Layout {
        /// Corner radius for cards and containers
        static let cornerRadius: CGFloat = 16

        /// Small corner radius for buttons
        static let smallCornerRadius: CGFloat = 8

        /// Standard padding
        static let padding: CGFloat = 16

        /// Small padding
        static let smallPadding: CGFloat = 8

        /// Large padding
        static let largePadding: CGFloat = 24

        /// Life total font size
        static let lifeFontSize: CGFloat = 56

        /// Commander damage font size
        static let commanderDamageFontSize: CGFloat = 18

        /// Counter font size
        static let counterFontSize: CGFloat = 16

        /// Player name font size
        static let playerNameFontSize: CGFloat = 20

        /// Border width for player quadrants
        static let borderWidth: CGFloat = 3

        /// Border width for eliminated players
        static let eliminatedBorderWidth: CGFloat = 1

        /// Shadow radius
        static let shadowRadius: CGFloat = 8

        /// Minimum tap target size (accessibility)
        static let minTapTargetSize: CGFloat = 44
    }

    // MARK: - Colors

    enum Colors {
        /// Magic The Gathering brand colors
        static let magicGold = Color(hex: "B8860B")

        /// Background colors
        static let backgroundPrimary = Color(hex: "1A1A1A")
        static let backgroundSecondary = Color(hex: "2D2D2D")
        static let backgroundTertiary = Color(hex: "3A3A3A")

        /// Mana colors
        static let white = Color.white
        static let blue = Color(hex: "0E68AB")
        static let black = Color(hex: "150B00")
        static let red = Color(hex: "D3202A")
        static let green = Color(hex: "00733E")
        static let colorless = Color(hex: "BEB9B2")

        /// State colors
        static let lifeLoss = Color.red
        static let lifeGain = Color.green
        static let poison = Color(hex: "9D5B8B")
        static let energy = Color(hex: "4A90E2")
        static let experience = Color(hex: "F5A623")

        /// UI colors
        static let textPrimary = Color.white
        static let textSecondary = Color.gray
        static let textDisabled = Color(hex: "666666")

        /// Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        /// Eliminated player overlay
        static let eliminated = Color.black.opacity(0.7)
    }

    // MARK: - Animations

    enum Animation {
        /// Standard spring animation
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)

        /// Quick spring for small changes
        static let quickSpring = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.8)

        /// Smooth easing
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)

        /// Damage flash duration
        static let damageFlashDuration: TimeInterval = 0.5

        /// Life gain flash duration
        static let lifeGainFlashDuration: TimeInterval = 0.5

        /// Elimination animation duration
        static let eliminationDuration: TimeInterval = 0.8
    }

    // MARK: - Timing

    enum Timing {
        /// Auto-save interval (seconds)
        static let autoSaveInterval: TimeInterval = 30

        /// Action log fade out duration (seconds)
        static let actionLogFadeOut: TimeInterval = 10

        /// Maximum number of actions to show in recent log
        static let maxRecentActions: Int = 5

        /// Maximum number of actions in undo stack
        static let maxUndoStack: Int = 10

        /// Voice recognition timeout (seconds) - Phase 2
        static let voiceRecognitionTimeout: TimeInterval = 5

        /// Wake word listening timeout (seconds) - Phase 2
        static let wakeWordTimeout: TimeInterval = 30
    }

    // MARK: - Accessibility

    enum Accessibility {
        /// Minimum contrast ratio
        static let minContrastRatio: CGFloat = 4.5

        /// Dynamic type scaling
        static let supportsDynamicType: Bool = true

        /// VoiceOver labels
        static let lifeLabel = "Punti vita"
        static let commanderDamageLabel = "Danni da comandante"
        static let poisonLabel = "Poison counter"
        static let energyLabel = "Energy counter"
        static let experienceLabel = "Experience counter"
        static let monarchLabel = "Monarch"
        static let initiativeLabel = "Initiative"
    }

    // MARK: - Persistence

    enum Persistence {
        /// Core Data model name
        static let modelName = "CommanderScorekeeper"

        /// User defaults keys
        static let lastPlayedSessionKey = "lastPlayedSession"
        static let appVersionKey = "appVersion"
        static let firstLaunchKey = "firstLaunch"
    }

    // MARK: - Voice Recognition (Phase 2)

    enum Voice {
        /// Wake words
        static let wakeWords = ["hey commander", "ehi commander"]

        /// Minimum speaker recognition confidence
        static let minSpeakerConfidence: Float = 0.85

        /// TTS playback rate
        static let ttsRate: Float = 1.1

        /// Voice calibration repetitions
        static let calibrationRepetitions: Int = 3
    }

    // MARK: - Symbols

    enum Symbols {
        static let poison = "☠️"
        static let energy = "⚡"
        static let experience = "🎓"
        static let monarch = "👑"
        static let initiative = "🎲"
        static let eliminated = "💀"
        static let commanderDamage = "⚔️"
        static let heart = "❤️"
        static let checkmark = "✓"
    }
}

// MARK: - Color Extension for Hex

extension Color {
    /// Create a Color from a hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Get mana color for a color identity
    static func manaColor(for identity: String) -> Color {
        switch identity.uppercased() {
        case "W":
            return Constants.Colors.white
        case "U":
            return Constants.Colors.blue
        case "B":
            return Constants.Colors.black
        case "R":
            return Constants.Colors.red
        case "G":
            return Constants.Colors.green
        default:
            return Constants.Colors.colorless
        }
    }

    /// Get gradient for multicolor identity
    static func gradientForColorIdentity(_ colors: [String]) -> LinearGradient {
        guard !colors.isEmpty else {
            return LinearGradient(
                colors: [Constants.Colors.colorless],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        let colorValues = colors.map { Color.manaColor(for: $0) }
        return LinearGradient(
            colors: colorValues,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

//
//  HapticManager.swift
//  CommanderScorekeeper
//
//  Manages haptic feedback throughout the app.
//  Provides contextual tactile responses for user actions.
//

import UIKit

/// Manages haptic feedback for enhanced user experience
@MainActor
final class HapticManager {

    /// Shared singleton instance
    static let shared = HapticManager()

    /// Haptic generators (cached for performance)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Prepare generators for minimal latency
        prepareGenerators()
    }

    // MARK: - Preparation

    /// Prepare all generators (call before expected use)
    func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Impact Feedback

    /// Light impact (for small changes like counter increments)
    func light() {
        impactLight.impactOccurred()
        impactLight.prepare()
    }

    /// Medium impact (for life changes, state changes)
    func medium() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Heavy impact (for significant events like eliminations)
    func heavy() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }

    // MARK: - Selection Feedback

    /// Selection changed (for UI navigation, picker changes)
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Notification Feedback

    /// Success notification (for completed actions, saves)
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Warning notification (for reversible errors, confirmations)
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Error notification (for errors, invalid actions)
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    // MARK: - Contextual Feedback

    /// Life change feedback (scaled by amount)
    func lifeChange(amount: Int) {
        let absAmount = abs(amount)

        if absAmount >= 10 {
            heavy()
        } else if absAmount >= 5 {
            medium()
        } else {
            light()
        }
    }

    /// Commander damage feedback
    func commanderDamage(amount: Int, isLethal: Bool) {
        if isLethal {
            // Double heavy impact for lethal damage
            heavy()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.heavy()
            }
        } else if amount >= 10 {
            heavy()
        } else {
            medium()
        }
    }

    /// Player elimination feedback
    func playerEliminated() {
        // Triple heavy impact for dramatic effect
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.heavy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.heavy()
        }
    }

    /// Counter change feedback
    func counterChange(type: String, amount: Int) {
        switch type {
        case "poison":
            // Poison is dangerous, use medium/heavy
            if abs(amount) >= 5 {
                heavy()
            } else {
                medium()
            }

        case "energy", "experience":
            // Lighter feedback for accumulating resources
            light()

        default:
            light()
        }
    }

    /// State change feedback (Monarch, Initiative)
    func stateChange() {
        medium()
    }

    /// Voice command recognized
    func voiceCommandRecognized() {
        success()
    }

    /// Voice command failed
    func voiceCommandFailed() {
        error()
    }

    /// Undo action
    func undo() {
        // Two light impacts for "going back"
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.light()
        }
    }

    /// Game saved
    func gameSaved() {
        success()
    }

    /// Button tap
    func buttonTap() {
        light()
    }

    /// Toggle changed
    func toggle() {
        selection()
    }
}

// MARK: - Convenience Extensions

extension HapticManager {
    /// Provide haptic feedback based on game action type
    func feedback(for actionType: GameActionType, value: Int = 0, isLethal: Bool = false) {
        switch actionType {
        case .lifeChange:
            lifeChange(amount: value)

        case .commanderDamage:
            commanderDamage(amount: value, isLethal: isLethal)

        case .poisonCounter:
            counterChange(type: "poison", amount: value)

        case .energyCounter:
            counterChange(type: "energy", amount: value)

        case .experienceCounter:
            counterChange(type: "experience", amount: value)

        case .monarchChange, .initiativeChange:
            stateChange()

        case .playerElimination:
            playerEliminated()

        case .gameStart:
            success()

        case .gameEnd:
            heavy()
        }
    }
}

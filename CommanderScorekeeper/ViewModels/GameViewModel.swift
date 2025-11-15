//
//  GameViewModel.swift
//  CommanderScorekeeper
//
//  Main ViewModel for active game state management.
//  Handles all game logic, player stats, actions, and undo functionality.
//

import Foundation
import Combine
import CoreData
import SwiftUI

/// ViewModel managing an active Commander game
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The active game session
    @Published var session: GameSession

    /// Players (cached for performance)
    @Published var players: [Player] = []

    /// Recent actions for UI display
    @Published var recentActions: [GameAction] = []

    /// Game duration (updated every second)
    @Published var duration: TimeInterval = 0

    /// Whether game is paused
    @Published var isPaused: Bool = false

    /// Undo stack (last N actions)
    @Published var undoStack: [GameAction] = []

    /// Flash states for damage visualization
    @Published var damageFlashStates: [UUID: (isActive: Bool, isDamage: Bool)] = [:]

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()

    // Timer for duration updates
    private var durationTimer: Timer?

    // Auto-save timer
    private var autoSaveTimer: Timer?

    // MARK: - Initialization

    init(session: GameSession, persistenceController: PersistenceController = .shared) {
        self.session = session
        self.persistenceController = persistenceController

        // Load players
        self.players = session.playersArray
        self.recentActions = session.recentActions()
        self.duration = session.currentDuration

        setupTimers()
    }

    deinit {
        stopTimers()
    }

    // MARK: - Timer Management

    private func setupTimers() {
        // Duration timer (updates every second)
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }

        // Auto-save timer (every 30 seconds)
        autoSaveTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.Timing.autoSaveInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.autoSave()
            }
        }
    }

    private func stopTimers() {
        durationTimer?.invalidate()
        durationTimer = nil
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    private func updateDuration() {
        guard !isPaused else { return }
        duration = session.currentDuration
        session.updateDuration()
    }

    private func autoSave() {
        guard !isPaused else { return }
        persistenceController.save()
        #if DEBUG
        print("🔄 Auto-saved game session")
        #endif
    }

    // MARK: - Game Control

    /// Pause the game
    func pause() {
        isPaused = true
        HapticManager.shared.medium()
    }

    /// Resume the game
    func resume() {
        isPaused = false
        HapticManager.shared.medium()
    }

    /// End the game
    func endGame() {
        session.endGame()
        stopTimers()
        persistenceController.save()
        HapticManager.shared.heavy()
    }

    /// Save the game manually
    func saveGame() {
        persistenceController.save()
        HapticManager.shared.gameSaved()
    }

    // MARK: - Life Totals

    /// Change a player's life total
    func changeLife(for player: Player, amount: Int) {
        let oldLife = player.currentLife
        player.currentLife += Int32(amount)

        // Create action
        let action = GameAction.createLifeChange(
            in: persistenceController.viewContext,
            actor: player,
            amount: amount,
            session: session
        )

        addToUndoStack(action)
        updateRecentActions()
        checkForElimination(player: player)

        // Visual feedback
        flashDamage(for: player, isDamage: amount < 0)
        HapticManager.shared.lifeChange(amount: amount)

        saveGame()

        #if DEBUG
        print("💚 \(player.name): \(oldLife) → \(player.currentLife) (\(amount.signedString))")
        #endif
    }

    // MARK: - Commander Damage

    /// Apply commander damage from one player to another
    func applyCommanderDamage(from attacker: Player, to defender: Player, amount: Int) {
        guard attacker.id != defender.id else {
            HapticManager.shared.error()
            print("❌ Cannot take commander damage from own commander")
            return
        }

        var damageDict = defender.commanderDamage
        let currentDamage = damageDict[attacker.id] ?? 0
        damageDict[attacker.id] = currentDamage + amount
        defender.commanderDamage = damageDict

        // Also reduce life
        defender.currentLife -= Int32(amount)

        // Create action
        let action = GameAction.createCommanderDamage(
            in: persistenceController.viewContext,
            from: attacker,
            to: defender,
            amount: amount,
            session: session
        )

        addToUndoStack(action)
        updateRecentActions()
        checkForElimination(player: defender)

        // Check if lethal
        let isLethal = damageDict[attacker.id] ?? 0 >= Constants.GameRules.lethalCommanderDamage

        // Visual feedback
        flashDamage(for: defender, isDamage: true)
        HapticManager.shared.commanderDamage(amount: amount, isLethal: isLethal)

        saveGame()

        #if DEBUG
        print("⚔️ \(defender.name) takes \(amount) commander damage from \(attacker.commanderName) (total: \(damageDict[attacker.id] ?? 0))")
        #endif
    }

    // MARK: - Counters

    /// Add poison counters to a player
    func addPoisonCounters(to player: Player, amount: Int) {
        player.poisonCounters += Int32(amount)

        let action = GameAction.createPoisonCounter(
            in: persistenceController.viewContext,
            target: player,
            amount: amount,
            session: session
        )

        addToUndoStack(action)
        updateRecentActions()
        checkForElimination(player: player)

        HapticManager.shared.counterChange(type: "poison", amount: amount)
        saveGame()
    }

    /// Add energy counters to a player
    func addEnergyCounters(to player: Player, amount: Int) {
        player.energyCounters = max(0, player.energyCounters + Int32(amount))

        let action = GameAction.createEnergyCounter(
            in: persistenceController.viewContext,
            target: player,
            amount: amount,
            session: session
        )

        addToUndoStack(action)
        updateRecentActions()

        HapticManager.shared.counterChange(type: "energy", amount: amount)
        saveGame()
    }

    /// Add experience counters to a player
    func addExperienceCounters(to player: Player, amount: Int) {
        player.experienceCounters = max(0, player.experienceCounters + Int32(amount))

        let action = GameAction.createExperienceCounter(
            in: persistenceController.viewContext,
            target: player,
            amount: amount,
            session: session
        )

        addToUndoStack(action)
        updateRecentActions()

        HapticManager.shared.counterChange(type: "experience", amount: amount)
        saveGame()
    }

    // MARK: - State Changes

    /// Set a player as the Monarch
    func setMonarch(_ player: Player) {
        // Remove monarch from all players
        players.forEach { $0.hasMonarch = false }

        // Set new monarch
        player.hasMonarch = true

        let action = GameAction.createMonarchChange(
            in: persistenceController.viewContext,
            newMonarch: player,
            session: session
        )

        addToUndoStack(action)
        updateRecentActions()

        HapticManager.shared.stateChange()
        saveGame()
    }

    /// Set a player as having the Initiative
    func setInitiative(_ player: Player) {
        // Remove initiative from all players
        players.forEach { $0.hasInitiative = false }

        // Set new initiative holder
        player.hasInitiative = true

        let action = GameAction.createInitiativeChange(
            in: persistenceController.viewContext,
            newInitiative: player,
            session: session
        )

        addToUndoStack(action)
        updateRecentActions()

        HapticManager.shared.stateChange()
        saveGame()
    }

    // MARK: - Elimination

    /// Check if a player should be eliminated and handle it
    private func checkForElimination(player: Player) {
        guard !player.isEliminated else { return }

        var eliminationReason: String?

        // Check life total
        if player.currentLife <= 0 {
            eliminationReason = "Punti vita a 0"
        }

        // Check poison
        if player.poisonCounters >= Constants.GameRules.lethalPoison {
            eliminationReason = "10 poison counter"
        }

        // Check commander damage
        for (attackerID, damage) in player.commanderDamage {
            if damage >= Constants.GameRules.lethalCommanderDamage {
                if let attacker = players.first(where: { $0.id == attackerID }) {
                    eliminationReason = "21 danni da comandante (\(attacker.commanderName))"
                }
            }
        }

        if let reason = eliminationReason {
            eliminatePlayer(player, reason: reason)
        }
    }

    /// Eliminate a player from the game
    private func eliminatePlayer(_ player: Player, reason: String) {
        player.isEliminated = true
        player.eliminationReason = reason

        let action = GameAction.createElimination(
            in: persistenceController.viewContext,
            player: player,
            reason: reason,
            session: session
        )

        addToUndoStack(action)
        updateRecentActions()

        HapticManager.shared.playerEliminated()
        saveGame()

        #if DEBUG
        print("💀 \(player.name) eliminated: \(reason)")
        #endif

        // Check if game is over (only 1 player remaining)
        let activePlayers = players.filter { !$0.isEliminated }
        if activePlayers.count <= 1 {
            endGame()
        }
    }

    // MARK: - Undo

    /// Undo the last action
    func undoLastAction() {
        guard let lastAction = undoStack.popLast() else {
            HapticManager.shared.error()
            return
        }

        // Find affected player
        if let targetID = lastAction.targetID,
           let player = players.first(where: { $0.id == targetID }) {

            // Restore previous state
            lastAction.restorePreviousState(to: player)
        }

        // Remove action from session
        persistenceController.viewContext.delete(lastAction)

        updateRecentActions()
        HapticManager.shared.undo()
        saveGame()

        #if DEBUG
        print("↩️ Undone: \(lastAction.actionDescription)")
        #endif
    }

    /// Check if undo is available
    var canUndo: Bool {
        !undoStack.isEmpty
    }

    // MARK: - Helper Methods

    private func addToUndoStack(_ action: GameAction) {
        undoStack.append(action)

        // Keep only last N actions
        if undoStack.count > Constants.Timing.maxUndoStack {
            undoStack.removeFirst()
        }
    }

    private func updateRecentActions() {
        recentActions = session.recentActions(limit: Constants.Timing.maxRecentActions)
    }

    private func flashDamage(for player: Player, isDamage: Bool) {
        damageFlashStates[player.id] = (isActive: true, isDamage: isDamage)

        // Reset after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Animation.damageFlashDuration) { [weak self] in
            self?.damageFlashStates[player.id] = (isActive: false, isDamage: isDamage)
        }
    }

    // MARK: - Convenience Getters

    /// Get flash state for a player
    func getFlashState(for player: Player) -> (isActive: Bool, isDamage: Bool) {
        damageFlashStates[player.id] ?? (isActive: false, isDamage: false)
    }

    /// Get commander damage received by a player from another
    func getCommanderDamage(defender: Player, attacker: Player) -> Int {
        defender.commanderDamage[attacker.id] ?? 0
    }

    /// Check if commander damage is lethal
    func isCommanderDamageLethal(defender: Player, attacker: Player) -> Bool {
        getCommanderDamage(defender: defender, attacker: attacker) >= Constants.GameRules.lethalCommanderDamage
    }
}

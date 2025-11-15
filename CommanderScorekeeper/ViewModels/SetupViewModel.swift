//
//  SetupViewModel.swift
//  CommanderScorekeeper
//
//  ViewModel for game setup flow.
//  Manages player configuration and validation before starting a game.
//

import Foundation
import Combine
import SwiftUI

/// Configuration for a single player during setup
struct PlayerConfiguration: Identifiable {
    let id = UUID()
    var name: String = ""
    var commanderName: String = ""
    var colorIdentity: [String] = []
    var voiceCalibrationProgress: Int = 0 // 0-3 for Phase 2

    var isValid: Bool {
        !name.isEmpty && !commanderName.isEmpty
    }

    var isFullyConfigured: Bool {
        isValid && !colorIdentity.isEmpty
    }
}

/// ViewModel managing game setup state and validation
@MainActor
final class SetupViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Player configurations (4 players for Commander)
    @Published var players: [PlayerConfiguration]

    /// Currently selected player index for editing
    @Published var selectedPlayerIndex: Int = 0

    /// Commander search query for autocomplete
    @Published var searchQuery: String = ""

    /// Autocomplete suggestions
    @Published var commanderSuggestions: [Commander] = []

    /// Validation errors
    @Published var validationError: String?

    /// Whether the setup is complete and valid
    @Published var isValid: Bool = false

    /// Whether to show the review screen
    @Published var showReview: Bool = false

    // MARK: - Dependencies

    private let commanderDatabase = CommanderDatabase.shared
    private let persistenceController: PersistenceController

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController

        // Initialize 4 empty player configurations
        self.players = (0..<Constants.GameRules.numberOfPlayers).map { index in
            var config = PlayerConfiguration()
            // Set default names for easier testing
            #if DEBUG
            config.name = "Player \(index + 1)"
            #endif
            return config
        }

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Validate whenever players change
        $players
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] players in
                self?.validateSetup(players: players)
            }
            .store(in: &cancellables)

        // Update commander suggestions when search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.updateCommanderSuggestions(query: query)
            }
            .store(in: &cancellables)
    }

    // MARK: - Player Management

    /// Update a player configuration
    func updatePlayer(at index: Int, _ update: (inout PlayerConfiguration) -> Void) {
        guard players.indices.contains(index) else { return }
        update(&players[index])
    }

    /// Set commander for current player
    func setCommander(_ commander: Commander, for index: Int) {
        updatePlayer(at: index) { player in
            player.commanderName = commander.name
            player.colorIdentity = commander.colorIdentity
        }

        HapticManager.shared.selection()
        searchQuery = ""
        commanderSuggestions = []
    }

    /// Auto-detect color identity from commander name
    func autoDetectColorIdentity(for index: Int) {
        guard let player = players[safe: index] else { return }

        if let commander = commanderDatabase.findCommander(name: player.commanderName) {
            updatePlayer(at: index) { config in
                config.colorIdentity = commander.colorIdentity
            }
            HapticManager.shared.success()
        }
    }

    /// Toggle a color in the identity
    func toggleColor(_ color: String, for index: Int) {
        updatePlayer(at: index) { player in
            if player.colorIdentity.contains(color) {
                player.colorIdentity.removeAll { $0 == color }
            } else {
                player.colorIdentity.append(color)
                // Sort in WUBRG order
                let order = ["W", "U", "B", "R", "G"]
                player.colorIdentity.sort { order.firstIndex(of: $0) ?? 0 < order.firstIndex(of: $1) ?? 0 }
            }
        }
        HapticManager.shared.light()
    }

    // MARK: - Commander Search

    private func updateCommanderSuggestions(query: String) {
        if query.isEmpty {
            commanderSuggestions = []
        } else {
            commanderSuggestions = commanderDatabase.search(query: query, limit: 10)
        }
    }

    /// Get popular commanders for suggestions
    func getPopularCommanders() -> [Commander] {
        commanderDatabase.getPopularCommanders(limit: 10)
    }

    // MARK: - Validation

    private func validateSetup(players: [PlayerConfiguration]) {
        validationError = nil

        // Check if all players have at least name and commander
        let invalidPlayers = players.enumerated().filter { !$0.element.isValid }

        if !invalidPlayers.isEmpty {
            let playerNumbers = invalidPlayers.map { "Giocatore \($0.offset + 1)" }.joined(separator: ", ")
            validationError = "Completa i dati per: \(playerNumbers)"
            isValid = false
            return
        }

        // Check for duplicate names
        let names = players.map { $0.name }
        if Set(names).count != names.count {
            validationError = "I nomi dei giocatori devono essere unici"
            isValid = false
            return
        }

        // Check for duplicate commanders (optional warning, not blocking)
        let commanders = players.map { $0.commanderName }
        if Set(commanders).count != commanders.count {
            // This is allowed in Commander (same deck matchup), just a note
            #if DEBUG
            print("⚠️ Duplicate commanders detected")
            #endif
        }

        isValid = true
    }

    /// Validate and proceed to review
    func proceedToReview() {
        guard isValid else {
            HapticManager.shared.error()
            return
        }

        HapticManager.shared.success()
        showReview = true
    }

    // MARK: - Game Creation

    /// Create and start a new game
    func startGame() -> GameSession? {
        guard isValid else {
            validationError = "Configurazione non valida"
            return nil
        }

        let playerConfigs = players.map {
            (name: $0.name, commanderName: $0.commanderName, colorIdentity: $0.colorIdentity)
        }

        let session = persistenceController.createGameSession(playerConfigs: playerConfigs)

        HapticManager.shared.success()

        return session
    }

    // MARK: - Reset

    /// Reset all player configurations
    func reset() {
        players = (0..<Constants.GameRules.numberOfPlayers).map { _ in
            PlayerConfiguration()
        }
        selectedPlayerIndex = 0
        searchQuery = ""
        commanderSuggestions = []
        validationError = nil
        showReview = false

        HapticManager.shared.light()
    }

    /// Quick fill with demo data (for testing)
    func fillDemoData() {
        let demoConfigs = [
            ("Alice", "Atraxa, Praetors' Voice", ["W", "U", "B", "G"]),
            ("Bob", "Krenko, Mob Boss", ["R"]),
            ("Charlie", "Muldrotha, the Gravetide", ["U", "B", "G"]),
            ("Diana", "Edgar Markov", ["W", "B", "R"])
        ]

        for (index, (name, commander, colors)) in demoConfigs.enumerated() {
            updatePlayer(at: index) { player in
                player.name = name
                player.commanderName = commander
                player.colorIdentity = colors
            }
        }

        HapticManager.shared.success()
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

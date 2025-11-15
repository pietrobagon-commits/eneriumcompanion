//
//  PlayerSetupCard.swift
//  CommanderScorekeeper
//
//  View for configuring a single player during game setup.
//  Includes name, commander selection, and color identity picker.
//

import SwiftUI

struct PlayerSetupCard: View {

    // MARK: - Properties

    @ObservedObject var viewModel: SetupViewModel
    let playerIndex: Int

    @FocusState private var isNameFocused: Bool
    @FocusState private var isCommanderFocused: Bool

    @State private var showCommanderPicker = false

    private var player: PlayerConfiguration {
        viewModel.players[playerIndex]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Constants.Layout.padding) {
            // Header
            headerSection

            // Player Name
            playerNameField

            // Commander Selection
            commanderSelectionSection

            // Color Identity Picker
            if !player.commanderName.isEmpty {
                colorIdentityPicker
            }

            // Validation Status
            validationStatus

            Spacer()
        }
        .padding(Constants.Layout.padding)
        .background(Constants.Colors.backgroundSecondary)
        .cornerRadius(Constants.Layout.cornerRadius)
        .magicCardStyle(borderColors: player.colorIdentity.isEmpty
            ? [Constants.Colors.magicGold]
            : player.colorIdentity.map { Color.manaColor(for: $0) }
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Giocatore \(playerIndex + 1)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)

            Spacer()

            if player.isFullyConfigured {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Constants.Colors.success)
                    .font(.title2)
            }
        }
    }

    // MARK: - Player Name Field

    private var playerNameField: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.smallPadding) {
            Text("Nome Giocatore")
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)

            TextField("Inserisci nome...", text: Binding(
                get: { player.name },
                set: { newValue in
                    viewModel.updatePlayer(at: playerIndex) { $0.name = newValue }
                }
            ))
            .focused($isNameFocused)
            .textFieldStyle(.plain)
            .padding()
            .background(Constants.Colors.backgroundPrimary)
            .cornerRadius(Constants.Layout.smallCornerRadius)
            .foregroundColor(Constants.Colors.textPrimary)
        }
    }

    // MARK: - Commander Selection

    private var commanderSelectionSection: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.smallPadding) {
            Text("Comandante")
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)

            HStack {
                TextField("Cerca comandante...", text: Binding(
                    get: { player.commanderName },
                    set: { newValue in
                        viewModel.updatePlayer(at: playerIndex) { $0.commanderName = newValue }
                        viewModel.searchQuery = newValue
                    }
                ))
                .focused($isCommanderFocused)
                .textFieldStyle(.plain)
                .padding()
                .background(Constants.Colors.backgroundPrimary)
                .cornerRadius(Constants.Layout.smallCornerRadius)
                .foregroundColor(Constants.Colors.textPrimary)

                // Auto-detect button
                if !player.commanderName.isEmpty {
                    Button(action: {
                        viewModel.autoDetectColorIdentity(for: playerIndex)
                    }) {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                            .foregroundColor(Constants.Colors.magicGold)
                    }
                    .padding(.horizontal, Constants.Layout.smallPadding)
                    .accessibleButton(
                        label: "Auto-rileva identità colore",
                        hint: "Rileva automaticamente i colori del comandante"
                    )
                }
            }

            // Commander suggestions
            if isCommanderFocused && !viewModel.commanderSuggestions.isEmpty {
                commanderSuggestionsList
            }
        }
    }

    private var commanderSuggestionsList: some View {
        ScrollView {
            VStack(spacing: Constants.Layout.smallPadding) {
                ForEach(viewModel.commanderSuggestions) { commander in
                    CommanderSuggestionRow(commander: commander) {
                        viewModel.setCommander(commander, for: playerIndex)
                        isCommanderFocused = false
                    }
                }
            }
            .padding(Constants.Layout.smallPadding)
        }
        .frame(maxHeight: 200)
        .background(Constants.Colors.backgroundPrimary)
        .cornerRadius(Constants.Layout.smallCornerRadius)
    }

    // MARK: - Color Identity Picker

    private var colorIdentityPicker: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.smallPadding) {
            Text("Identità Colore")
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)

            HStack(spacing: Constants.Layout.smallPadding) {
                ForEach(["W", "U", "B", "R", "G"], id: \.self) { color in
                    ColorButton(
                        color: color,
                        isSelected: player.colorIdentity.contains(color)
                    ) {
                        viewModel.toggleColor(color, for: playerIndex)
                    }
                }
            }
        }
    }

    // MARK: - Validation Status

    @ViewBuilder
    private var validationStatus: some View {
        if player.isFullyConfigured {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Constants.Colors.success)
                Text("Configurazione completa")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.success)
            }
        } else if !player.name.isEmpty || !player.commanderName.isEmpty {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(Constants.Colors.warning)
                Text("Completa tutti i campi")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.warning)
            }
        }
    }
}

// MARK: - Supporting Views

/// Row displaying a commander suggestion
struct CommanderSuggestionRow: View {
    let commander: Commander
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(commander.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Constants.Colors.textPrimary)

                    Text(commander.type)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }

                Spacer()

                // Color identity symbols
                HStack(spacing: 4) {
                    ForEach(commander.colorIdentity, id: \.self) { color in
                        Circle()
                            .fill(Color.manaColor(for: color))
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(Constants.Layout.smallPadding)
            .background(Constants.Colors.backgroundSecondary)
            .cornerRadius(Constants.Layout.smallCornerRadius)
        }
    }
}

/// Button for selecting a mana color
struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.manaColor(for: color))
                    .frame(width: 50, height: 50)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
            }
        }
        .opacity(isSelected ? 1.0 : 0.5)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    PlayerSetupCard(viewModel: SetupViewModel(), playerIndex: 0)
        .preferredColorScheme(.dark)
}

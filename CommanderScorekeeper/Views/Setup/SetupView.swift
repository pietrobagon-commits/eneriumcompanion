//
//  SetupView.swift
//  CommanderScorekeeper
//
//  Main setup view for configuring a new game.
//  Allows navigation between players and validation before starting.
//

import SwiftUI

struct SetupView: View {

    // MARK: - Properties

    @StateObject private var viewModel = SetupViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showingReview = false
    @State private var navigateToGame = false
    @State private var createdSession: GameSession?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Constants.Colors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Player tabs
                    playerTabBar

                    // Current player card
                    TabView(selection: $viewModel.selectedPlayerIndex) {
                        ForEach(0..<Constants.GameRules.numberOfPlayers, id: \.self) { index in
                            ScrollView {
                                PlayerSetupCard(viewModel: viewModel, playerIndex: index)
                                    .padding()
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Bottom actions
                    bottomActionBar
                }
            }
            .navigationTitle("Nuova Partita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textSecondary)
                }

                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Demo") {
                        viewModel.fillDemoData()
                    }
                    .foregroundColor(Constants.Colors.magicGold)
                }
                #endif
            }
            .sheet(isPresented: $showingReview) {
                ReviewView(viewModel: viewModel) { session in
                    createdSession = session
                    navigateToGame = true
                    showingReview = false
                }
            }
            .navigationDestination(isPresented: $navigateToGame) {
                if let session = createdSession {
                    GameView(session: session)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Player Tab Bar

    private var playerTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<Constants.GameRules.numberOfPlayers, id: \.self) { index in
                PlayerTab(
                    playerNumber: index + 1,
                    isSelected: viewModel.selectedPlayerIndex == index,
                    isConfigured: viewModel.players[index].isFullyConfigured,
                    colorIdentity: viewModel.players[index].colorIdentity
                ) {
                    withAnimation {
                        viewModel.selectedPlayerIndex = index
                    }
                    HapticManager.shared.selection()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Constants.Layout.smallPadding)
        .background(Constants.Colors.backgroundSecondary)
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: Constants.Layout.smallPadding) {
            // Validation error
            if let error = viewModel.validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Constants.Colors.error)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.error)
                }
                .padding(.horizontal)
            }

            // Start game button
            Button(action: {
                showingReview = true
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Rivedi e Inizia")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isValid ? Constants.Colors.magicGold : Constants.Colors.textDisabled)
                .foregroundColor(.black)
                .cornerRadius(Constants.Layout.smallCornerRadius)
            }
            .disabled(!viewModel.isValid)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Constants.Colors.backgroundSecondary)
    }
}

// MARK: - Supporting Views

/// Tab button for selecting a player
struct PlayerTab: View {
    let playerNumber: Int
    let isSelected: Bool
    let isConfigured: Bool
    let colorIdentity: [String]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("P\(playerNumber)")
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .regular)

                if isConfigured {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.success)
                } else {
                    Circle()
                        .fill(Constants.Colors.textDisabled)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.Layout.smallPadding)
            .background(
                isSelected
                    ? Color.gradientForColorIdentity(colorIdentity)
                    : LinearGradient(
                        colors: [Constants.Colors.backgroundPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .cornerRadius(Constants.Layout.smallCornerRadius)
        }
        .foregroundColor(isSelected ? .black : Constants.Colors.textPrimary)
    }
}

/// Review view before starting game
struct ReviewView: View {
    @ObservedObject var viewModel: SetupViewModel
    let onStart: (GameSession) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Layout.padding) {
                        Text("Rivedi Configurazione")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.Colors.textPrimary)

                        ForEach(Array(viewModel.players.enumerated()), id: \.offset) { index, player in
                            PlayerReviewCard(player: player, playerNumber: index + 1)
                        }

                        // Start button
                        Button(action: {
                            if let session = viewModel.startGame() {
                                onStart(session)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                Text("Inizia Partita!")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Constants.Colors.magicGold)
                            .foregroundColor(.black)
                            .cornerRadius(Constants.Layout.cornerRadius)
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Riepilogo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Indietro") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// Card displaying player configuration in review
struct PlayerReviewCard: View {
    let player: PlayerConfiguration
    let playerNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.smallPadding) {
            // Header
            HStack {
                Text("Giocatore \(playerNumber)")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
                Spacer()
                // Color symbols
                HStack(spacing: 4) {
                    ForEach(player.colorIdentity, id: \.self) { color in
                        Circle()
                            .fill(Color.manaColor(for: color))
                            .frame(width: 16, height: 16)
                    }
                }
            }

            // Player name
            Text(player.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)

            // Commander
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(Constants.Colors.magicGold)
                Text(player.commanderName)
                    .font(.body)
                    .foregroundColor(Constants.Colors.textSecondary)
            }
        }
        .padding()
        .background(Constants.Colors.backgroundSecondary)
        .playerQuadrantStyle(colorIdentity: player.colorIdentity)
    }
}

// MARK: - Preview

#Preview {
    SetupView()
}

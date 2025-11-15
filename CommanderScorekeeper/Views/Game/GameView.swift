//
//  GameView.swift
//  CommanderScorekeeper
//
//  Main game view with 4-quadrant player layout.
//  Displays life totals, commander damage, and game state.
//  Landscape orientation recommended.
//

import SwiftUI

struct GameView: View {

    // MARK: - Properties

    @StateObject private var viewModel: GameViewModel
    @StateObject private var voiceViewModel: VoiceRecognitionViewModel

    @State private var showMenu = false
    @State private var showActionLog = false
    @State private var selectedPlayer: Player?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(session: GameSession) {
        let gameVM = GameViewModel(session: session)
        _viewModel = StateObject(wrappedValue: gameVM)
        _voiceViewModel = StateObject(wrappedValue: VoiceRecognitionViewModel(gameViewModel: gameVM))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Constants.Colors.backgroundPrimary
                    .ignoresSafeArea()

                // 4-quadrant layout
                quadrantLayout(size: geometry.size)

                // Overlay elements
                VStack {
                    // Top bar
                    topBar

                    Spacer()

                    // Action log (center overlay)
                    if !viewModel.recentActions.isEmpty && !showActionLog {
                        recentActionsOverlay
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer()

                    // Bottom controls
                    bottomControls
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedPlayer) { player in
                PlayerDetailSheet(player: player, viewModel: viewModel)
            }
            .sheet(isPresented: $showActionLog) {
                ActionLogView(actions: viewModel.recentActions)
            }
            .confirmationDialog("Menu", isPresented: $showMenu) {
                menuOptions
            }
            .confirmationDialog("Chi ha parlato?", isPresented: $voiceViewModel.showSpeakerSelection) {
                speakerSelectionOptions
            }
        }
        .statusBar(hidden: false)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .task {
            // Auto-start voice recognition on appear (Phase 2)
            // await voiceViewModel.startVoiceRecognition()
        }
        .onDisappear {
            voiceViewModel.stopVoiceRecognition()
        }
    }

    // MARK: - Quadrant Layout

    @ViewBuilder
    private func quadrantLayout(size: CGSize) -> some View {
        let quadrantWidth = size.width / 2
        let quadrantHeight = size.height / 2

        VStack(spacing: 2) {
            HStack(spacing: 2) {
                // Top-left
                if viewModel.players.indices.contains(0) {
                    PlayerQuadrant(
                        player: viewModel.players[0],
                        viewModel: viewModel,
                        rotation: .degrees(180)
                    )
                    .frame(width: quadrantWidth, height: quadrantHeight)
                    .onTapGesture {
                        selectedPlayer = viewModel.players[0]
                    }
                }

                // Top-right
                if viewModel.players.indices.contains(1) {
                    PlayerQuadrant(
                        player: viewModel.players[1],
                        viewModel: viewModel,
                        rotation: .degrees(180)
                    )
                    .frame(width: quadrantWidth, height: quadrantHeight)
                    .onTapGesture {
                        selectedPlayer = viewModel.players[1]
                    }
                }
            }

            HStack(spacing: 2) {
                // Bottom-left
                if viewModel.players.indices.contains(2) {
                    PlayerQuadrant(
                        player: viewModel.players[2],
                        viewModel: viewModel,
                        rotation: .degrees(0)
                    )
                    .frame(width: quadrantWidth, height: quadrantHeight)
                    .onTapGesture {
                        selectedPlayer = viewModel.players[2]
                    }
                }

                // Bottom-right
                if viewModel.players.indices.contains(3) {
                    PlayerQuadrant(
                        player: viewModel.players[3],
                        viewModel: viewModel,
                        rotation: .degrees(0)
                    )
                    .frame(width: quadrantWidth, height: quadrantHeight)
                    .onTapGesture {
                        selectedPlayer = viewModel.players[3]
                    }
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Timer
            HStack(spacing: 8) {
                Image(systemName: viewModel.isPaused ? "pause.circle.fill" : "timer")
                    .foregroundColor(Constants.Colors.magicGold)
                Text(viewModel.session.formattedDuration)
                    .font(.headline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Constants.Colors.backgroundSecondary.opacity(0.9))
            .cornerRadius(Constants.Layout.smallCornerRadius)

            Spacer()

            // Voice indicator (Phase 2)
            VoiceIndicator(voiceViewModel: voiceViewModel)

            Spacer()

            // Menu button
            Button(action: { showMenu = true }) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundColor(Constants.Colors.magicGold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Constants.Colors.backgroundSecondary.opacity(0.9))
            .cornerRadius(Constants.Layout.smallCornerRadius)
        }
    }

    // MARK: - Recent Actions Overlay

    private var recentActionsOverlay: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(Constants.Colors.magicGold)
                Text("Ultime Azioni")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { showActionLog = true }) {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                }
            }
            .foregroundColor(Constants.Colors.textPrimary)

            ForEach(viewModel.recentActions.prefix(3)) { action in
                HStack {
                    Text(action.timestamp.timeString)
                        .font(.caption2)
                        .foregroundColor(Constants.Colors.textSecondary)
                    Text(action.actionDescription)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: 400)
        .background(Constants.Colors.backgroundSecondary.opacity(0.95))
        .cornerRadius(Constants.Layout.cornerRadius)
        .shadow(radius: 8)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 16) {
            // Undo button
            Button(action: {
                viewModel.undoLastAction()
            }) {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Annulla")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(viewModel.canUndo ? Constants.Colors.backgroundSecondary.opacity(0.9) : Constants.Colors.backgroundSecondary.opacity(0.5))
                .foregroundColor(viewModel.canUndo ? Constants.Colors.textPrimary : Constants.Colors.textDisabled)
                .cornerRadius(Constants.Layout.smallCornerRadius)
            }
            .disabled(!viewModel.canUndo)

            // Pause/Resume button
            Button(action: {
                if viewModel.isPaused {
                    viewModel.resume()
                } else {
                    viewModel.pause()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    Text(viewModel.isPaused ? "Riprendi" : "Pausa")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Constants.Colors.backgroundSecondary.opacity(0.9))
                .foregroundColor(Constants.Colors.textPrimary)
                .cornerRadius(Constants.Layout.smallCornerRadius)
            }
        }
    }

    // MARK: - Menu Options

    private var menuOptions: some View {
        Group {
            // Voice toggle (Phase 2)
            Button(voiceViewModel.isActive ? "Disattiva Voce" : "Attiva Voce") {
                Task {
                    await voiceViewModel.toggleVoiceRecognition()
                }
            }

            Button("Salva Partita") {
                viewModel.saveGame()
            }

            Button("Log Completo") {
                showActionLog = true
            }

            Button("Termina Partita", role: .destructive) {
                viewModel.endGame()
                dismiss()
            }

            Button("Annulla", role: .cancel) {}
        }
    }

    // MARK: - Speaker Selection

    private var speakerSelectionOptions: some View {
        ForEach(viewModel.players, id: \.id) { player in
            Button(player.name) {
                voiceViewModel.executeCommandForSpeaker(player)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GameView(session: PersistenceController.preview.fetchActiveSessions().first!)
}

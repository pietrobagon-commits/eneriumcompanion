//
//  ContentView.swift
//  CommanderScorekeeper
//
//  Main content view with navigation.
//  Welcome screen with options to start new game or load saved games.
//

import SwiftUI
import CoreData

struct ContentView: View {

    // MARK: - Properties

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GameSession.startDate, ascending: false)],
        predicate: NSPredicate(format: "endDate == nil"),
        animation: .default
    )
    private var activeSessions: FetchedResults<GameSession>

    @State private var showingSetup = false
    @State private var selectedSession: GameSession?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Main actions
                        mainActions

                        // Active sessions (if any)
                        if !activeSessions.isEmpty {
                            activeSessionsSection
                        }

                        // Statistics (optional)
                        statisticsSection

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $showingSetup) {
                SetupView()
            }
            .navigationDestination(item: $selectedSession) { session in
                GameView(session: session)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Constants.Colors.backgroundPrimary,
                Constants.Colors.backgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // App icon placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Constants.Colors.magicGold,
                                Constants.Colors.magicGold.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.black)
            }
            .shadow(color: Constants.Colors.magicGold.opacity(0.3), radius: 20)

            // Title
            Text("Commander")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(Constants.Colors.textPrimary)

            Text("Scorekeeper")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(Constants.Colors.magicGold)

            // Subtitle
            Text("Traccia i punteggi delle tue partite Commander")
                .font(.subheadline)
                .foregroundColor(Constants.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    // MARK: - Main Actions

    private var mainActions: some View {
        VStack(spacing: 16) {
            // New Game button
            Button(action: {
                showingSetup = true
                HapticManager.shared.buttonTap()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Nuova Partita")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Constants.Colors.magicGold)
                .foregroundColor(.black)
                .cornerRadius(Constants.Layout.cornerRadius)
                .shadow(color: Constants.Colors.magicGold.opacity(0.3), radius: 10)
            }

            // Saved Games button
            NavigationLink(destination: SavedGamesListView()) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                    Text("Partite Salvate")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Constants.Colors.backgroundSecondary)
                .foregroundColor(Constants.Colors.textPrimary)
                .cornerRadius(Constants.Layout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius)
                        .strokeBorder(Constants.Colors.magicGold, lineWidth: 2)
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Active Sessions

    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(Constants.Colors.success)
                Text("Partite in Corso")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.textPrimary)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(activeSessions.prefix(3)) { session in
                    Button(action: {
                        selectedSession = session
                        HapticManager.shared.buttonTap()
                    }) {
                        GameSessionRow(session: session)
                    }
                }
            }
            .padding(.horizontal)

            if activeSessions.count > 3 {
                NavigationLink(destination: SavedGamesListView()) {
                    HStack {
                        Text("Vedi tutte (\(activeSessions.count))")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(Constants.Colors.magicGold)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Statistiche")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            HStack(spacing: 12) {
                StatCard(
                    title: "Partite",
                    value: "\(PersistenceController.shared.getTotalGamesPlayed())",
                    icon: "gamecontroller"
                )

                StatCard(
                    title: "Ore Giocate",
                    value: formatPlayTime(PersistenceController.shared.getTotalPlayTime()),
                    icon: "clock"
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private func formatPlayTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        if hours < 1 {
            let minutes = Int(seconds) / 60
            return "\(minutes)m"
        }
        return "\(hours)h"
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(Constants.Colors.magicGold)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.textPrimary)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Constants.Colors.backgroundSecondary)
        .cornerRadius(Constants.Layout.cornerRadius)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

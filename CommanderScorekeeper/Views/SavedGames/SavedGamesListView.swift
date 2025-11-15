//
//  SavedGamesListView.swift
//  CommanderScorekeeper
//
//  List view for saved game sessions.
//  Allows loading, deleting, and viewing game history.
//

import SwiftUI
import CoreData

struct SavedGamesListView: View {

    // MARK: - Properties

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GameSession.startDate, ascending: false)],
        animation: .default
    )
    private var sessions: FetchedResults<GameSession>

    @State private var selectedSession: GameSession?
    @State private var showingDeleteConfirmation = false
    @State private var sessionToDelete: GameSession?

    // MARK: - Body

    var body: some View {
        ZStack {
            Constants.Colors.backgroundPrimary
                .ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                sessionsList
            }
        }
        .navigationTitle("Partite Salvate")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedSession) { session in
            GameView(session: session)
        }
        .confirmationDialog(
            "Eliminare questa partita?",
            isPresented: $showingDeleteConfirmation,
            presenting: sessionToDelete
        ) { session in
            Button("Elimina", role: .destructive) {
                deleteSession(session)
            }
            Button("Annulla", role: .cancel) {}
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 80))
                .foregroundColor(Constants.Colors.textDisabled)

            Text("Nessuna partita salvata")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textSecondary)

            Text("Le partite salvate appariranno qui")
                .font(.body)
                .foregroundColor(Constants.Colors.textDisabled)
        }
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        List {
            // Active sessions
            if !activeSessions.isEmpty {
                Section {
                    ForEach(activeSessions) { session in
                        GameSessionRow(session: session)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSession = session
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text("In Corso")
                        .foregroundColor(Constants.Colors.success)
                }
                .listRowBackground(Constants.Colors.backgroundSecondary)
            }

            // Completed sessions
            if !completedSessions.isEmpty {
                Section {
                    ForEach(completedSessions) { session in
                        GameSessionRow(session: session)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSession = session
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text("Terminate")
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                .listRowBackground(Constants.Colors.backgroundSecondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Computed Properties

    private var activeSessions: [GameSession] {
        sessions.filter { $0.isActive }
    }

    private var completedSessions: [GameSession] {
        sessions.filter { !$0.isActive }
    }

    // MARK: - Actions

    private func deleteSession(_ session: GameSession) {
        withAnimation {
            viewContext.delete(session)

            do {
                try viewContext.save()
                HapticManager.shared.success()
            } catch {
                print("Error deleting session: \(error)")
                HapticManager.shared.error()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SavedGamesListView()
            .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
    }
}

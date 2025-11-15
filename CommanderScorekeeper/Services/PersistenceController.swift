//
//  PersistenceController.swift
//  CommanderScorekeeper
//
//  Core Data persistence controller.
//  Manages the Core Data stack and provides context management.
//

import CoreData
import Foundation

/// Manages Core Data persistence layer
final class PersistenceController: ObservableObject {

    /// Shared singleton instance
    static let shared = PersistenceController()

    /// Preview instance for SwiftUI previews (in-memory)
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Create sample data for previews
        let viewContext = controller.container.viewContext

        // Create a sample game session
        let session = GameSession.create(
            in: viewContext,
            playerConfigs: [
                (name: "Alice", commanderName: "Atraxa, Praetors' Voice", colorIdentity: ["W", "U", "B", "G"]),
                (name: "Bob", commanderName: "Krenko, Mob Boss", colorIdentity: ["R"]),
                (name: "Charlie", commanderName: "Muldrotha, the Gravetide", colorIdentity: ["U", "B", "G"]),
                (name: "Diana", commanderName: "Edgar Markov", colorIdentity: ["W", "B", "R"])
            ]
        )

        // Add some sample actions
        let players = session.playersArray

        _ = GameAction.createLifeChange(in: viewContext, actor: players[0], amount: -5, session: session)
        _ = GameAction.createCommanderDamage(in: viewContext, from: players[1], to: players[0], amount: 8, session: session)
        _ = GameAction.createPoisonCounter(in: viewContext, target: players[2], amount: 3, session: session)

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    /// The persistent container
    let container: NSPersistentContainer

    /// Main view context (use on main thread only)
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: Constants.Persistence.modelName)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Configure merge policy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            #if DEBUG
            print("✅ Core Data store loaded: \(storeDescription.url?.lastPathComponent ?? "unknown")")
            #endif
        }
    }

    // MARK: - Context Management

    /// Create a new background context for performing work off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Perform work on background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    // MARK: - Save Operations

    /// Save the view context if it has changes
    func save() {
        let context = viewContext

        guard context.hasChanges else {
            #if DEBUG
            print("ℹ️ No changes to save")
            #endif
            return
        }

        do {
            try context.save()
            #if DEBUG
            print("✅ Context saved successfully")
            #endif
        } catch {
            let nsError = error as NSError
            print("❌ Error saving context: \(nsError), \(nsError.userInfo)")

            // In production, handle this error appropriately
            // For now, we'll attempt to rollback
            context.rollback()
        }
    }

    /// Save a background context
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("❌ Error saving background context: \(nsError), \(nsError.userInfo)")
            context.rollback()
        }
    }

    // MARK: - Game Session Management

    /// Create a new game session
    func createGameSession(
        playerConfigs: [(name: String, commanderName: String, colorIdentity: [String])]
    ) -> GameSession {
        let session = GameSession.create(in: viewContext, playerConfigs: playerConfigs)
        save()
        return session
    }

    /// Fetch all game sessions
    func fetchAllSessions() -> [GameSession] {
        GameSession.fetchAllSessions(in: viewContext)
    }

    /// Fetch active game sessions
    func fetchActiveSessions() -> [GameSession] {
        GameSession.fetchActiveSessions(in: viewContext)
    }

    /// Fetch completed game sessions
    func fetchCompletedSessions() -> [GameSession] {
        GameSession.fetchCompletedSessions(in: viewContext)
    }

    /// Delete a game session
    func deleteSession(_ session: GameSession) {
        viewContext.delete(session)
        save()
    }

    /// Delete multiple game sessions
    func deleteSessions(_ sessions: [GameSession]) {
        sessions.forEach { viewContext.delete($0) }
        save()
    }

    // MARK: - Cleanup

    /// Delete all data (use with caution!)
    func deleteAllData() {
        performBackgroundTask { context in
            let entities = ["GameSession", "Player", "GameAction"]

            for entityName in entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try context.execute(deleteRequest)
                    try context.save()
                    print("✅ Deleted all \(entityName) entities")
                } catch {
                    print("❌ Error deleting \(entityName): \(error)")
                }
            }
        }
    }

    /// Delete old completed sessions (keep last N sessions)
    func cleanupOldSessions(keepLast: Int = 50) {
        let allSessions = fetchCompletedSessions()

        guard allSessions.count > keepLast else { return }

        let sessionsToDelete = Array(allSessions.dropFirst(keepLast))
        deleteSessions(sessionsToDelete)

        print("🧹 Cleaned up \(sessionsToDelete.count) old sessions")
    }

    // MARK: - Statistics

    /// Get total number of games played
    func getTotalGamesPlayed() -> Int {
        let request: NSFetchRequest<GameSession> = GameSession.fetchRequest()
        request.predicate = NSPredicate(format: "endDate != nil")

        do {
            return try viewContext.count(for: request)
        } catch {
            print("❌ Error counting games: \(error)")
            return 0
        }
    }

    /// Get total play time (in seconds)
    func getTotalPlayTime() -> TimeInterval {
        let request: NSFetchRequest<GameSession> = GameSession.fetchRequest()
        request.predicate = NSPredicate(format: "endDate != nil")

        do {
            let sessions = try viewContext.fetch(request)
            return sessions.reduce(0) { $0 + TimeInterval($1.duration) }
        } catch {
            print("❌ Error calculating play time: \(error)")
            return 0
        }
    }
}

// MARK: - Error Types

enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidContext

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Errore nel salvataggio: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Errore nel caricamento: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Errore nell'eliminazione: \(error.localizedDescription)"
        case .invalidContext:
            return "Contesto Core Data non valido"
        }
    }
}

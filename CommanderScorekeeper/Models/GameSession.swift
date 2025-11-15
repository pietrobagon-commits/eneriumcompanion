//
//  GameSession.swift
//  CommanderScorekeeper
//
//  Core Data entity representing a complete Commander game session.
//  Contains players, actions log, and game state.
//

import Foundation
import CoreData

/// Represents a complete Commander game session
@objc(GameSession)
public class GameSession: NSManagedObject, Identifiable {

    /// Unique identifier for the session
    @NSManaged public var id: UUID

    /// When the game started
    @NSManaged public var startDate: Date

    /// When the game ended (nil if still in progress)
    @NSManaged public var endDate: Date?

    /// Total game duration in seconds
    @NSManaged public var duration: Int32

    /// Relationship to players (4 players in Commander)
    @NSManaged public var players: NSSet?

    /// Relationship to action log
    @NSManaged public var actionLog: NSSet?

    // MARK: - Computed Properties

    /// Players as a typed array
    public var playersArray: [Player] {
        let set = players as? Set<Player> ?? []
        return set.sorted { $0.position < $1.position }
    }

    /// Action log as a typed array, sorted by timestamp (most recent first)
    public var actionsArray: [GameAction] {
        let set = actionLog as? Set<GameAction> ?? []
        return set.sorted { $0.timestamp > $1.timestamp }
    }

    /// Get recent actions (default: last 5)
    public func recentActions(limit: Int = 5) -> [GameAction] {
        Array(actionsArray.prefix(limit))
    }

    /// Check if game is currently active
    public var isActive: Bool {
        endDate == nil
    }

    /// Get the current duration (live if active, final if ended)
    public var currentDuration: TimeInterval {
        if let endDate = endDate {
            return endDate.timeIntervalSince(startDate)
        } else {
            return Date().timeIntervalSince(startDate)
        }
    }

    /// Format duration as MM:SS or HH:MM:SS
    public var formattedDuration: String {
        let totalSeconds = Int(currentDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Get a preview string for saved games list
    public var preview: String {
        let playerNames = playersArray.map { $0.name }.joined(separator: ", ")
        let status = isActive ? "In corso" : "Terminata"
        return "\(playerNames) • \(status) • \(formattedDuration)"
    }

    /// Get winning player (if game is ended)
    public var winner: Player? {
        guard !isActive else { return nil }
        return playersArray.first { !$0.isEliminated }
    }

    // MARK: - Initialization

    public override func awakeFromInsert() {
        super.awakeFromInsert()

        id = UUID()
        startDate = Date()
        duration = 0
    }

    /// Create a new game session with players
    public static func create(
        in context: NSManagedObjectContext,
        playerConfigs: [(name: String, commanderName: String, colorIdentity: [String])]
    ) -> GameSession {
        let session = GameSession(context: context)

        // Create players
        for (index, config) in playerConfigs.enumerated() {
            let player = Player.create(
                in: context,
                name: config.name,
                commanderName: config.commanderName,
                colorIdentity: config.colorIdentity,
                position: index
            )
            player.gameSession = session
        }

        // Create game start action
        let startAction = GameAction(context: context)
        startAction.type = .gameStart
        startAction.actionDescription = "Partita iniziata"
        startAction.gameSession = session

        return session
    }

    /// End the game session
    public func endGame() {
        endDate = Date()
        duration = Int32(currentDuration)

        // Create game end action
        if let context = managedObjectContext {
            let endAction = GameAction(context: context)
            endAction.type = .gameEnd
            endAction.gameSession = self

            if let winner = winner {
                endAction.actionDescription = "Partita terminata - Vince \(winner.name)"
            } else {
                endAction.actionDescription = "Partita terminata"
            }
        }
    }

    /// Update duration (call periodically while game is active)
    public func updateDuration() {
        if isActive {
            duration = Int32(currentDuration)
        }
    }
}

// MARK: - Core Data Relationships

extension GameSession {
    @objc(addPlayersObject:)
    @NSManaged public func addToPlayers(_ value: Player)

    @objc(removePlayersObject:)
    @NSManaged public func removeFromPlayers(_ value: Player)

    @objc(addPlayers:)
    @NSManaged public func addToPlayers(_ values: NSSet)

    @objc(removePlayers:)
    @NSManaged public func removeFromPlayers(_ values: NSSet)

    @objc(addActionLogObject:)
    @NSManaged public func addToActionLog(_ value: GameAction)

    @objc(removeActionLogObject:)
    @NSManaged public func removeFromActionLog(_ value: GameAction)

    @objc(addActionLog:)
    @NSManaged public func addToActionLog(_ values: NSSet)

    @objc(removeActionLog:)
    @NSManaged public func removeFromActionLog(_ values: NSSet)
}

// MARK: - Fetching

extension GameSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameSession> {
        return NSFetchRequest<GameSession>(entityName: "GameSession")
    }

    /// Fetch all game sessions, sorted by start date (most recent first)
    public static func fetchAllSessions(in context: NSManagedObjectContext) -> [GameSession] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GameSession.startDate, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }

    /// Fetch active game sessions
    public static func fetchActiveSessions(in context: NSManagedObjectContext) -> [GameSession] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "endDate == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GameSession.startDate, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching active sessions: \(error)")
            return []
        }
    }

    /// Fetch completed game sessions
    public static func fetchCompletedSessions(in context: NSManagedObjectContext) -> [GameSession] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "endDate != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GameSession.endDate, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching completed sessions: \(error)")
            return []
        }
    }

    /// Delete a session and all related data
    public func delete(from context: NSManagedObjectContext) {
        context.delete(self)
    }
}

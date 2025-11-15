//
//  Player.swift
//  CommanderScorekeeper
//
//  Core Data entity representing a player in a Commander game.
//  Tracks life totals, commander damage, counters, and game states.
//

import Foundation
import CoreData

/// Represents a player in a Commander game with all their stats and states
@objc(Player)
public class Player: NSManagedObject, Identifiable {

    /// Unique identifier for the player
    @NSManaged public var id: UUID

    /// Player's chosen name
    @NSManaged public var name: String

    /// Name of the commander being used
    @NSManaged public var commanderName: String

    /// Color identity of the commander (stored as comma-separated string: "W,U,B,R,G")
    @NSManaged public var colorIdentityString: String

    /// Serialized voice profile data for speaker recognition (Phase 2)
    @NSManaged public var voiceProfile: Data?

    /// Current life total (starts at 40 in Commander)
    @NSManaged public var currentLife: Int32

    /// Commander damage received from each opponent (JSON encoded as {UUID: Int})
    @NSManaged public var commanderDamageData: Data?

    /// Poison counters (lethal at 10)
    @NSManaged public var poisonCounters: Int32

    /// Energy counters
    @NSManaged public var energyCounters: Int32

    /// Experience counters
    @NSManaged public var experienceCounters: Int32

    /// Whether player has the Monarch status
    @NSManaged public var hasMonarch: Bool

    /// Whether player has the Initiative
    @NSManaged public var hasInitiative: Bool

    /// Whether player has been eliminated from the game
    @NSManaged public var isEliminated: Bool

    /// Reason for elimination (e.g., "Life total", "Commander damage from Atraxa", "Poison")
    @NSManaged public var eliminationReason: String?

    /// Position in the game (0-3) for UI layout
    @NSManaged public var position: Int32

    /// Relationship to the game session
    @NSManaged public var gameSession: GameSession?

    // MARK: - Computed Properties

    /// Color identity as an array of strings
    public var colorIdentity: [String] {
        get {
            colorIdentityString.split(separator: ",").map(String.init)
        }
        set {
            colorIdentityString = newValue.joined(separator: ",")
        }
    }

    /// Commander damage as a dictionary [UUID: Int]
    public var commanderDamage: [UUID: Int] {
        get {
            guard let data = commanderDamageData,
                  let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
                return [:]
            }
            // Convert string keys back to UUIDs
            return dict.reduce(into: [UUID: Int]()) { result, pair in
                if let uuid = UUID(uuidString: pair.key) {
                    result[uuid] = pair.value
                }
            }
        }
        set {
            // Convert UUID keys to strings for JSON encoding
            let stringDict = newValue.reduce(into: [String: Int]()) { result, pair in
                result[pair.key.uuidString] = pair.value
            }
            commanderDamageData = try? JSONEncoder().encode(stringDict)
        }
    }

    /// Check if player is eliminated by any win condition
    public var shouldBeEliminated: Bool {
        currentLife <= 0 ||
        poisonCounters >= 10 ||
        commanderDamage.values.contains(where: { $0 >= 21 })
    }

    /// Get the lethal commander damage amounts for UI highlighting
    public func getLethalCommanderDamage() -> [UUID] {
        commanderDamage.filter { $0.value >= 21 }.map { $0.key }
    }

    // MARK: - Initialization

    /// Initialize a new player with default values
    public override func awakeFromInsert() {
        super.awakeFromInsert()

        id = UUID()
        name = ""
        commanderName = ""
        colorIdentityString = ""
        currentLife = 40
        poisonCounters = 0
        energyCounters = 0
        experienceCounters = 0
        hasMonarch = false
        hasInitiative = false
        isEliminated = false
        position = 0
        commanderDamage = [:]
    }

    /// Create a player with specified values
    public static func create(
        in context: NSManagedObjectContext,
        name: String,
        commanderName: String,
        colorIdentity: [String],
        position: Int
    ) -> Player {
        let player = Player(context: context)
        player.name = name
        player.commanderName = commanderName
        player.colorIdentity = colorIdentity
        player.position = Int32(position)
        return player
    }
}

// MARK: - Fetching

extension Player {
    /// Fetch request for all players
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Player> {
        return NSFetchRequest<Player>(entityName: "Player")
    }

    /// Fetch players for a specific game session
    public static func fetchPlayers(for session: GameSession, in context: NSManagedObjectContext) -> [Player] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "gameSession == %@", session)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Player.position, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching players: \(error)")
            return []
        }
    }
}

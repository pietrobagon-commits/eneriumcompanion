//
//  GameAction.swift
//  CommanderScorekeeper
//
//  Core Data entity representing an action in the game.
//  Used for logging, undo functionality, and game history.
//

import Foundation
import CoreData

/// Types of actions that can occur in a Commander game
public enum GameActionType: String, CaseIterable {
    case lifeChange = "life_change"
    case commanderDamage = "commander_damage"
    case poisonCounter = "poison_counter"
    case energyCounter = "energy_counter"
    case experienceCounter = "experience_counter"
    case monarchChange = "monarch_change"
    case initiativeChange = "initiative_change"
    case playerElimination = "player_elimination"
    case gameStart = "game_start"
    case gameEnd = "game_end"
}

/// Represents a game action for logging and undo functionality
@objc(GameAction)
public class GameAction: NSManagedObject, Identifiable {

    /// Unique identifier for the action
    @NSManaged public var id: UUID

    /// When the action occurred
    @NSManaged public var timestamp: Date

    /// Type of action (stored as string)
    @NSManaged public var typeString: String

    /// UUID of the player who performed the action
    @NSManaged public var actorID: UUID?

    /// UUID of the player who is affected by the action
    @NSManaged public var targetID: UUID?

    /// Numerical value associated with the action (e.g., damage amount, life change)
    @NSManaged public var value: Int32

    /// Human-readable description for UI display
    @NSManaged public var actionDescription: String

    /// Previous state data for undo functionality (JSON encoded)
    @NSManaged public var previousStateData: Data?

    /// Relationship to the game session
    @NSManaged public var gameSession: GameSession?

    // MARK: - Computed Properties

    /// Type of action as enum
    public var type: GameActionType {
        get {
            GameActionType(rawValue: typeString) ?? .lifeChange
        }
        set {
            typeString = newValue.rawValue
        }
    }

    // MARK: - Initialization

    public override func awakeFromInsert() {
        super.awakeFromInsert()

        id = UUID()
        timestamp = Date()
        typeString = GameActionType.lifeChange.rawValue
        value = 0
        actionDescription = ""
    }

    /// Create a life change action
    public static func createLifeChange(
        in context: NSManagedObjectContext,
        actor: Player,
        amount: Int,
        session: GameSession
    ) -> GameAction {
        let action = GameAction(context: context)
        action.type = .lifeChange
        action.actorID = actor.id
        action.targetID = actor.id
        action.value = Int32(amount)

        let verb = amount > 0 ? "guadagna" : "perde"
        let absAmount = abs(amount)
        action.actionDescription = "\(actor.name) \(verb) \(absAmount) \(absAmount == 1 ? "vita" : "vite")"

        action.gameSession = session
        action.savePreviousState(player: actor)

        return action
    }

    /// Create a commander damage action
    public static func createCommanderDamage(
        in context: NSManagedObjectContext,
        from attacker: Player,
        to defender: Player,
        amount: Int,
        session: GameSession
    ) -> GameAction {
        let action = GameAction(context: context)
        action.type = .commanderDamage
        action.actorID = attacker.id
        action.targetID = defender.id
        action.value = Int32(amount)
        action.actionDescription = "\(defender.name) subisce \(amount) da comandante \(attacker.commanderName)"
        action.gameSession = session
        action.savePreviousState(player: defender)

        return action
    }

    /// Create a poison counter action
    public static func createPoisonCounter(
        in context: NSManagedObjectContext,
        target: Player,
        amount: Int,
        session: GameSession
    ) -> GameAction {
        let action = GameAction(context: context)
        action.type = .poisonCounter
        action.targetID = target.id
        action.value = Int32(amount)

        let verb = amount > 0 ? "prende" : "rimuove"
        let absAmount = abs(amount)
        action.actionDescription = "\(target.name) \(verb) \(absAmount) poison counter"

        action.gameSession = session
        action.savePreviousState(player: target)

        return action
    }

    /// Create an energy counter action
    public static func createEnergyCounter(
        in context: NSManagedObjectContext,
        target: Player,
        amount: Int,
        session: GameSession
    ) -> GameAction {
        let action = GameAction(context: context)
        action.type = .energyCounter
        action.targetID = target.id
        action.value = Int32(amount)

        let verb = amount > 0 ? "guadagna" : "perde"
        let absAmount = abs(amount)
        action.actionDescription = "\(target.name) \(verb) \(absAmount) energy"

        action.gameSession = session
        action.savePreviousState(player: target)

        return action
    }

    /// Create an experience counter action
    public static func createExperienceCounter(
        in context: NSManagedObjectContext,
        target: Player,
        amount: Int,
        session: GameSession
    ) -> GameAction {
        let action = GameAction(context: context)
        action.type = .experienceCounter
        action.targetID = target.id
        action.value = Int32(amount)

        let verb = amount > 0 ? "guadagna" : "perde"
        let absAmount = abs(amount)
        action.actionDescription = "\(target.name) \(verb) \(absAmount) experience"

        action.gameSession = session
        action.savePreviousState(player: target)

        return action
    }

    /// Create a monarch change action
    public static func createMonarchChange(
        in context: NSManagedObjectContext,
        newMonarch: Player,
        session: GameSession
    ) -> GameAction {
        let action = GameAction(context: context)
        action.type = .monarchChange
        action.actorID = newMonarch.id
        action.targetID = newMonarch.id
        action.actionDescription = "\(newMonarch.name) diventa il Monarch"
        action.gameSession = session

        return action
    }

    /// Create an initiative change action
    public static func createInitiativeChange(
        in context: NSManagedObjectContext,
        newInitiative: Player,
        session: GameSession
    ) -> GameAction {
        let action = GameAction(context: context)
        action.type = .initiativeChange
        action.actorID = newInitiative.id
        action.targetID = newInitiative.id
        action.actionDescription = "\(newInitiative.name) prende l'iniziativa"
        action.gameSession = session

        return action
    }

    /// Create a player elimination action
    public static func createElimination(
        in context: NSManagedObjectContext,
        player: Player,
        reason: String,
        session: GameSession
    ) -> GameAction {
        let action = GameAction(context: context)
        action.type = .playerElimination
        action.targetID = player.id
        action.actionDescription = "\(player.name) è stato eliminato: \(reason)"
        action.gameSession = session

        return action
    }

    // MARK: - Undo Support

    /// Save the previous state for undo functionality
    private func savePreviousState(player: Player) {
        let state: [String: Any] = [
            "life": player.currentLife,
            "poison": player.poisonCounters,
            "energy": player.energyCounters,
            "experience": player.experienceCounters,
            "commanderDamage": player.commanderDamage.mapValues { $0 }.reduce(into: [String: Int]()) { result, pair in
                result[pair.key.uuidString] = pair.value
            },
            "isEliminated": player.isEliminated
        ]

        previousStateData = try? JSONSerialization.data(withJSONObject: state)
    }

    /// Restore previous state (for undo)
    public func restorePreviousState(to player: Player) {
        guard let data = previousStateData,
              let state = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if let life = state["life"] as? Int32 {
            player.currentLife = life
        }
        if let poison = state["poison"] as? Int32 {
            player.poisonCounters = poison
        }
        if let energy = state["energy"] as? Int32 {
            player.energyCounters = energy
        }
        if let experience = state["experience"] as? Int32 {
            player.experienceCounters = experience
        }
        if let commanderDamageDict = state["commanderDamage"] as? [String: Int] {
            player.commanderDamage = commanderDamageDict.reduce(into: [UUID: Int]()) { result, pair in
                if let uuid = UUID(uuidString: pair.key) {
                    result[uuid] = pair.value
                }
            }
        }
        if let eliminated = state["isEliminated"] as? Bool {
            player.isEliminated = eliminated
        }
    }
}

// MARK: - Fetching

extension GameAction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameAction> {
        return NSFetchRequest<GameAction>(entityName: "GameAction")
    }

    /// Fetch actions for a game session, sorted by timestamp
    public static func fetchActions(
        for session: GameSession,
        in context: NSManagedObjectContext,
        limit: Int? = nil
    ) -> [GameAction] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "gameSession == %@", session)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GameAction.timestamp, ascending: false)]

        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching actions: \(error)")
            return []
        }
    }
}

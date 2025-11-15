//
//  CommanderDatabase.swift
//  CommanderScorekeeper
//
//  Manager for the local database of popular Commander cards.
//  Provides autocomplete and color identity lookup.
//

import Foundation

/// Represents a Commander card with its essential information
public struct Commander: Codable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let colorIdentity: [String]
    public let type: String // e.g., "Legendary Creature — Human Wizard"
    public let power: String?
    public let toughness: String?

    public init(name: String, colorIdentity: [String], type: String, power: String? = nil, toughness: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorIdentity = colorIdentity
        self.type = type
        self.power = power
        self.toughness = toughness
    }

    /// Get a display string for color identity (e.g., "WUB" or "Colorless")
    public var colorIdentityString: String {
        colorIdentity.isEmpty ? "Colorless" : colorIdentity.joined()
    }

    /// Get color name(s) in Italian
    public var colorNamesItalian: String {
        if colorIdentity.isEmpty {
            return "Incolore"
        }

        let colorMap: [String: String] = [
            "W": "Bianco",
            "U": "Blu",
            "B": "Nero",
            "R": "Rosso",
            "G": "Verde"
        ]

        let names = colorIdentity.compactMap { colorMap[$0] }
        return names.joined(separator: ", ")
    }
}

/// Manages the local commander database
public class CommanderDatabase: ObservableObject {

    /// Singleton instance
    public static let shared = CommanderDatabase()

    /// All commanders in the database
    @Published public private(set) var commanders: [Commander] = []

    /// Search index for fast autocomplete
    private var searchIndex: [String: [Commander]] = [:]

    private init() {
        loadCommanders()
        buildSearchIndex()
    }

    /// Load commanders from JSON file
    private func loadCommanders() {
        guard let url = Bundle.main.url(forResource: "Commanders", withExtension: "json") else {
            print("Warning: Commanders.json not found, using default list")
            commanders = getDefaultCommanders()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            commanders = try JSONDecoder().decode([Commander].self, from: data)
            print("Loaded \(commanders.count) commanders from database")
        } catch {
            print("Error loading commanders: \(error)")
            commanders = getDefaultCommanders()
        }
    }

    /// Build search index for autocomplete
    private func buildSearchIndex() {
        searchIndex.removeAll()

        for commander in commanders {
            // Index by full name
            let lowercaseName = commander.name.lowercased()
            searchIndex[lowercaseName, default: []].append(commander)

            // Index by words in name for partial matching
            let words = lowercaseName.split(separator: " ")
            for word in words {
                searchIndex[String(word), default: []].append(commander)
            }
        }
    }

    /// Search commanders by name (autocomplete)
    public func search(query: String, limit: Int = 10) -> [Commander] {
        guard !query.isEmpty else { return [] }

        let lowercaseQuery = query.lowercased()

        // Exact matches first
        var results: [Commander] = []

        // Full name starts with query
        let exactMatches = commanders.filter { $0.name.lowercased().hasPrefix(lowercaseQuery) }
        results.append(contentsOf: exactMatches)

        // Contains query in name
        if results.count < limit {
            let containsMatches = commanders.filter {
                !results.contains($0) && $0.name.lowercased().contains(lowercaseQuery)
            }
            results.append(contentsOf: containsMatches)
        }

        return Array(results.prefix(limit))
    }

    /// Find a commander by exact name
    public func findCommander(name: String) -> Commander? {
        commanders.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Get color identity for a commander name
    public func getColorIdentity(for name: String) -> [String]? {
        findCommander(name: name)?.colorIdentity
    }

    /// Get popular commanders (for suggestions)
    public func getPopularCommanders(limit: Int = 20) -> [Commander] {
        Array(commanders.prefix(limit))
    }

    /// Default commander list (used if JSON fails to load)
    private func getDefaultCommanders() -> [Commander] {
        return [
            Commander(name: "Atraxa, Praetors' Voice", colorIdentity: ["W", "U", "B", "G"], type: "Legendary Creature — Phyrexian Angel", power: "4", toughness: "4"),
            Commander(name: "Edgar Markov", colorIdentity: ["W", "B", "R"], type: "Legendary Creature — Vampire Knight", power: "4", toughness: "4"),
            Commander(name: "The Ur-Dragon", colorIdentity: ["W", "U", "B", "R", "G"], type: "Legendary Creature — Dragon Avatar", power: "10", toughness: "10"),
            Commander(name: "Muldrotha, the Gravetide", colorIdentity: ["U", "B", "G"], type: "Legendary Creature — Elemental Avatar", power: "6", toughness: "6"),
            Commander(name: "Prossh, Skyraider of Kher", colorIdentity: ["B", "R", "G"], type: "Legendary Creature — Dragon", power: "5", toughness: "5"),
            Commander(name: "Kaalia of the Vast", colorIdentity: ["W", "B", "R"], type: "Legendary Creature — Human Cleric", power: "2", toughness: "2"),
            Commander(name: "Omnath, Locus of Creation", colorIdentity: ["W", "U", "R", "G"], type: "Legendary Creature — Elemental", power: "4", toughness: "4"),
            Commander(name: "Teysa Karlov", colorIdentity: ["W", "B"], type: "Legendary Creature — Human Advisor", power: "2", toughness: "4"),
            Commander(name: "Korvold, Fae-Cursed King", colorIdentity: ["B", "R", "G"], type: "Legendary Creature — Dragon Noble", power: "4", toughness: "4"),
            Commander(name: "Krenko, Mob Boss", colorIdentity: ["R"], type: "Legendary Creature — Goblin Warrior", power: "3", toughness: "3"),
            Commander(name: "Ghave, Guru of Spores", colorIdentity: ["W", "B", "G"], type: "Legendary Creature — Fungus Shaman", power: "0", toughness: "0"),
            Commander(name: "Breya, Etherium Shaper", colorIdentity: ["W", "U", "B", "R"], type: "Legendary Artifact Creature — Human", power: "4", toughness: "4"),
            Commander(name: "Oloro, Ageless Ascetic", colorIdentity: ["W", "U", "B"], type: "Legendary Creature — Giant Soldier", power: "4", toughness: "5"),
            Commander(name: "Narset, Enlightened Master", colorIdentity: ["W", "U", "R"], type: "Legendary Creature — Human Monk", power: "3", toughness: "2"),
            Commander(name: "Ezuri, Claw of Progress", colorIdentity: ["U", "G"], type: "Legendary Creature — Elf Warrior", power: "3", toughness: "3"),
            Commander(name: "Animar, Soul of Elements", colorIdentity: ["U", "R", "G"], type: "Legendary Creature — Elemental", power: "1", toughness: "1"),
            Commander(name: "Sliver Overlord", colorIdentity: ["W", "U", "B", "R", "G"], type: "Legendary Creature — Sliver Mutant", power: "7", toughness: "7"),
            Commander(name: "Ur-Dragon", colorIdentity: ["W", "U", "B", "R", "G"], type: "Legendary Creature — Dragon Avatar", power: "10", toughness: "10"),
            Commander(name: "Yuriko, the Tiger's Shadow", colorIdentity: ["U", "B"], type: "Legendary Creature — Human Ninja", power: "1", toughness: "3"),
            Commander(name: "Nekusar, the Mindrazer", colorIdentity: ["U", "B", "R"], type: "Legendary Creature — Zombie Wizard", power: "2", toughness: "4"),
            Commander(name: "Meren of Clan Nel Toth", colorIdentity: ["B", "G"], type: "Legendary Creature — Human Shaman", power: "3", toughness: "4"),
            Commander(name: "Karador, Ghost Chieftain", colorIdentity: ["W", "B", "G"], type: "Legendary Creature — Centaur Spirit", power: "3", toughness: "4"),
            Commander(name: "Derevi, Empyrial Tactician", colorIdentity: ["W", "U", "G"], type: "Legendary Creature — Bird Wizard", power: "2", toughness: "3"),
            Commander(name: "Tasigur, the Golden Fang", colorIdentity: ["U", "B", "G"], type: "Legendary Creature — Human Shaman", power: "4", toughness: "5"),
            Commander(name: "Saskia the Unyielding", colorIdentity: ["W", "B", "R", "G"], type: "Legendary Creature — Human Soldier", power: "3", toughness: "4")
        ]
    }
}

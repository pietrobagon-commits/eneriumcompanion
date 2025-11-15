//
//  NLPCommandParser.swift
//  CommanderScorekeeper
//
//  Natural Language Processing parser for voice commands in Italian.
//  Recognizes patterns and extracts game actions from spoken text.
//

import Foundation

/// Parsed command result
struct ParsedCommand {
    let type: GameActionType
    let actor: String? // Player name or "io"
    let target: String? // Target player name
    let value: Int
    let metadata: [String: String] // Additional info (e.g., commander name)

    var description: String {
        switch type {
        case .lifeChange:
            let who = actor ?? "Giocatore"
            let verb = value > 0 ? "guadagna" : "perde"
            return "\(who) \(verb) \(abs(value)) vite"

        case .commanderDamage:
            let who = target ?? "Giocatore"
            let from = metadata["commanderName"] ?? metadata["attackerName"] ?? "comandante"
            return "\(who) subisce \(value) da \(from)"

        case .poisonCounter:
            let who = target ?? actor ?? "Giocatore"
            return "\(who) prende \(value) poison"

        case .energyCounter:
            let who = target ?? actor ?? "Giocatore"
            let verb = value > 0 ? "guadagna" : "perde"
            return "\(who) \(verb) \(abs(value)) energy"

        case .experienceCounter:
            let who = target ?? actor ?? "Giocatore"
            return "\(who) guadagna \(value) experience"

        case .monarchChange:
            let who = target ?? actor ?? "Giocatore"
            return "\(who) diventa il Monarch"

        case .initiativeChange:
            let who = target ?? actor ?? "Giocatore"
            return "\(who) prende l'iniziativa"

        default:
            return "Comando non riconosciuto"
        }
    }
}

/// NLP command parser
final class NLPCommandParser {

    // MARK: - Properties

    private let playerNames: [String]
    private let commanderNames: [String: String] // playerName: commanderName

    // MARK: - Initialization

    init(playerNames: [String], commanders: [String: String]) {
        self.playerNames = playerNames.map { $0.lowercased() }
        self.commanderNames = commanders.mapValues { $0.lowercased() }

        #if DEBUG
        print("📝 NLP Parser initialized with players: \(playerNames)")
        #endif
    }

    // MARK: - Main Parsing

    /// Parse a voice command into a structured command
    func parse(command: String) -> ParsedCommand? {
        let normalized = normalizeCommand(command)

        #if DEBUG
        print("🔍 Parsing: '\(normalized)'")
        #endif

        // Try each pattern in order of specificity
        if let cmd = parseLifeChange(normalized) { return cmd }
        if let cmd = parseCommanderDamage(normalized) { return cmd }
        if let cmd = parsePoisonCounter(normalized) { return cmd }
        if let cmd = parseEnergyCounter(normalized) { return cmd }
        if let cmd = parseExperienceCounter(normalized) { return cmd }
        if let cmd = parseMonarchChange(normalized) { return cmd }
        if let cmd = parseInitiativeChange(normalized) { return cmd }

        #if DEBUG
        print("❌ No pattern matched")
        #endif

        return nil
    }

    // MARK: - Normalization

    private func normalizeCommand(_ command: String) -> String {
        var normalized = command.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove punctuation
        normalized = normalized.replacingOccurrences(of: "[.,!?;:]", with: "", options: .regularExpression)

        // Normalize common variations
        let substitutions: [String: String] = [
            "commander": "comandante",
            "general": "comandante",
            "life": "vite",
            "vita": "vite",
            "hp": "vite",
            "damage": "danni",
            "danno": "danni",
            "veleno": "poison",
            "infect": "poison",
            "energia": "energy",
            "esperienza": "experience",
            "exp": "experience"
        ]

        for (from, to) in substitutions {
            normalized = normalized.replacingOccurrences(of: from, with: to)
        }

        return normalized
    }

    // MARK: - Life Change Parsing

    private func parseLifeChange(_ command: String) -> ParsedCommand? {
        // Patterns:
        // "guadagno X vite"
        // "perdo X vite"
        // "[Nome] guadagna X vite"
        // "[Nome] perde X vite"

        let patterns: [(pattern: String, isGain: Bool)] = [
            (#"(?:io\s+)?guadagno\s+(\d+)\s+vite?"#, true),
            (#"(?:io\s+)?perdo\s+(\d+)\s+vite?"#, false),
            (#"(\w+)\s+guadagna\s+(\d+)\s+vite?"#, true),
            (#"(\w+)\s+perde\s+(\d+)\s+vite?"#, false),
            (#"aggiungi\s+(\d+)\s+vite?\s+a\s+(\w+)"#, true),
            (#"rimuovi\s+(\d+)\s+vite?\s+(?:da\s+)?(\w+)"#, false)
        ]

        for (pattern, isGain) in patterns {
            if let match = command.range(of: pattern, options: .regularExpression) {
                let matchedText = String(command[match])
                let components = matchedText.split(separator: " ")

                // Extract value
                guard let value = extractNumber(from: matchedText) else { continue }
                let signedValue = isGain ? value : -value

                // Extract player name
                let playerName = extractPlayerName(from: matchedText)

                return ParsedCommand(
                    type: .lifeChange,
                    actor: playerName ?? "io",
                    target: playerName ?? "io",
                    value: signedValue,
                    metadata: [:]
                )
            }
        }

        return nil
    }

    // MARK: - Commander Damage Parsing

    private func parseCommanderDamage(_ command: String) -> ParsedCommand? {
        // Patterns:
        // "subisco X da [NomeComandante]"
        // "subisco X da comandante [Nome]"
        // "[Nome] subisce X da [NomeComandante]"
        // "do X da comandante a [Nome]"

        let patterns: [String] = [
            #"(?:io\s+)?subisco\s+(\d+)\s+(?:da\s+)?(?:comandante\s+)?(\w+)"#,
            #"(?:io\s+)?prendo\s+(\d+)\s+(?:da\s+)?(?:comandante\s+)?(\w+)"#,
            #"(\w+)\s+subisce\s+(\d+)\s+(?:da\s+)?(?:comandante\s+)?(\w+)"#,
            #"(\w+)\s+prende\s+(\d+)\s+(?:da\s+)?(?:comandante\s+)?(\w+)"#,
            #"do\s+(\d+)\s+(?:da\s+)?comandante\s+a\s+(\w+)"#,
            #"(\d+)\s+danni\s+(?:da\s+)?comandante\s+a\s+(\w+)"#
        ]

        for pattern in patterns {
            if let match = command.range(of: pattern, options: .regularExpression) {
                let matchedText = String(command[match])

                guard let value = extractNumber(from: matchedText) else { continue }

                // Extract defender (who receives damage)
                let defender = extractPlayerName(from: matchedText) ?? "io"

                // Extract attacker/commander name
                let words = matchedText.split(separator: " ")
                var commanderName: String?
                var attackerName: String?

                if let fromIndex = words.firstIndex(of: "da") {
                    let nextIndex = fromIndex + 1
                    if nextIndex < words.count && words[nextIndex] != "comandante" {
                        let possibleName = String(words[nextIndex])
                        if isCommanderName(possibleName) {
                            commanderName = possibleName
                        } else if isPlayerName(possibleName) {
                            attackerName = possibleName
                        }
                    }
                }

                var metadata: [String: String] = [:]
                if let cmdName = commanderName {
                    metadata["commanderName"] = cmdName
                }
                if let atkName = attackerName {
                    metadata["attackerName"] = atkName
                }

                return ParsedCommand(
                    type: .commanderDamage,
                    actor: attackerName,
                    target: defender,
                    value: value,
                    metadata: metadata
                )
            }
        }

        return nil
    }

    // MARK: - Poison Counter Parsing

    private func parsePoisonCounter(_ command: String) -> ParsedCommand? {
        let patterns: [String] = [
            #"(?:io\s+)?prendo\s+(\d+)\s+poison"#,
            #"(?:io\s+)?prendo\s+(\d+)\s+veleno"#,
            #"(\w+)\s+prende\s+(\d+)\s+poison"#,
            #"aggiungi\s+(\d+)\s+poison\s+a\s+(\w+)"#,
            #"do\s+(\d+)\s+poison\s+a\s+(\w+)"#
        ]

        for pattern in patterns {
            if let match = command.range(of: pattern, options: .regularExpression) {
                let matchedText = String(command[match])

                guard let value = extractNumber(from: matchedText) else { continue }
                let playerName = extractPlayerName(from: matchedText) ?? "io"

                return ParsedCommand(
                    type: .poisonCounter,
                    actor: playerName,
                    target: playerName,
                    value: value,
                    metadata: [:]
                )
            }
        }

        return nil
    }

    // MARK: - Energy Counter Parsing

    private func parseEnergyCounter(_ command: String) -> ParsedCommand? {
        let patterns: [(pattern: String, isPositive: Bool)] = [
            (#"(?:io\s+)?guadagno\s+(\d+)\s+energy"#, true),
            (#"aggiungi\s+(\d+)\s+energy(?:\s+a\s+)?(\w+)?"#, true),
            (#"(\w+)\s+guadagna\s+(\d+)\s+energy"#, true),
            (#"rimuovi\s+(\d+)\s+energy(?:\s+da\s+)?(\w+)?"#, false),
            (#"(?:io\s+)?perdo\s+(\d+)\s+energy"#, false)
        ]

        for (pattern, isPositive) in patterns {
            if let match = command.range(of: pattern, options: .regularExpression) {
                let matchedText = String(command[match])

                guard let value = extractNumber(from: matchedText) else { continue }
                let signedValue = isPositive ? value : -value
                let playerName = extractPlayerName(from: matchedText) ?? "io"

                return ParsedCommand(
                    type: .energyCounter,
                    actor: playerName,
                    target: playerName,
                    value: signedValue,
                    metadata: [:]
                )
            }
        }

        return nil
    }

    // MARK: - Experience Counter Parsing

    private func parseExperienceCounter(_ command: String) -> ParsedCommand? {
        let patterns: [String] = [
            #"(?:io\s+)?guadagno\s+(\d+)\s+experience"#,
            #"aggiungi\s+(\d+)\s+experience(?:\s+a\s+)?(\w+)?"#,
            #"(\w+)\s+guadagna\s+(\d+)\s+experience"#
        ]

        for pattern in patterns {
            if let match = command.range(of: pattern, options: .regularExpression) {
                let matchedText = String(command[match])

                guard let value = extractNumber(from: matchedText) else { continue }
                let playerName = extractPlayerName(from: matchedText) ?? "io"

                return ParsedCommand(
                    type: .experienceCounter,
                    actor: playerName,
                    target: playerName,
                    value: value,
                    metadata: [:]
                )
            }
        }

        return nil
    }

    // MARK: - Monarch Change Parsing

    private func parseMonarchChange(_ command: String) -> ParsedCommand? {
        let patterns: [String] = [
            #"(?:io\s+)?divento\s+(?:il\s+)?monarch"#,
            #"(?:io\s+)?prendo\s+(?:il\s+)?monarch"#,
            #"(\w+)\s+diventa\s+(?:il\s+)?monarch"#,
            #"(\w+)\s+prende\s+(?:il\s+)?monarch"#
        ]

        for pattern in patterns {
            if command.range(of: pattern, options: .regularExpression) != nil {
                let matchedText = String(command[command.startIndex..<command.endIndex])
                let playerName = extractPlayerName(from: matchedText) ?? "io"

                return ParsedCommand(
                    type: .monarchChange,
                    actor: playerName,
                    target: playerName,
                    value: 0,
                    metadata: [:]
                )
            }
        }

        return nil
    }

    // MARK: - Initiative Change Parsing

    private func parseInitiativeChange(_ command: String) -> ParsedCommand? {
        let patterns: [String] = [
            #"(?:io\s+)?prendo\s+(?:l')?iniziativa"#,
            #"(?:io\s+)?divento\s+(?:l')?iniziativa"#,
            #"(\w+)\s+prende\s+(?:l')?iniziativa"#,
            #"(\w+)\s+ha\s+(?:l')?iniziativa"#
        ]

        for pattern in patterns {
            if command.range(of: pattern, options: .regularExpression) != nil {
                let matchedText = String(command[command.startIndex..<command.endIndex])
                let playerName = extractPlayerName(from: matchedText) ?? "io"

                return ParsedCommand(
                    type: .initiativeChange,
                    actor: playerName,
                    target: playerName,
                    value: 0,
                    metadata: [:]
                )
            }
        }

        return nil
    }

    // MARK: - Helper Methods

    private func extractNumber(from text: String) -> Int? {
        let pattern = #"\d+"#
        guard let match = text.range(of: pattern, options: .regularExpression) else {
            return nil
        }

        let numberString = String(text[match])
        return Int(numberString)
    }

    private func extractPlayerName(from text: String) -> String? {
        for playerName in playerNames {
            if text.contains(playerName) {
                return playerName
            }
        }
        return nil
    }

    private func isPlayerName(_ name: String) -> Bool {
        playerNames.contains(name.lowercased())
    }

    private func isCommanderName(_ name: String) -> Bool {
        commanderNames.values.contains { commander in
            commander.lowercased().contains(name.lowercased()) ||
            name.lowercased().contains(commander.lowercased().split(separator: " ").first ?? "")
        }
    }
}

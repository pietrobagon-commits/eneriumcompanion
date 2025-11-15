//
//  PlayerDetailSheet.swift
//  CommanderScorekeeper
//
//  Detailed player controls sheet.
//  Allows manual modification of life, commander damage, and counters.
//

import SwiftUI

struct PlayerDetailSheet: View {

    // MARK: - Properties

    let player: Player
    @ObservedObject var viewModel: GameViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: ControlTab = .life

    enum ControlTab: String, CaseIterable {
        case life = "Vita"
        case commanderDamage = "Cmd Dmg"
        case counters = "Counter"
        case status = "Stato"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Player header
                    playerHeader

                    // Tab selector
                    tabSelector

                    // Content
                    ScrollView {
                        VStack(spacing: Constants.Layout.padding) {
                            switch selectedTab {
                            case .life:
                                lifeControls
                            case .commanderDamage:
                                commanderDamageControls
                            case .counters:
                                counterControls
                            case .status:
                                statusControls
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(player.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.magicGold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Player Header

    private var playerHeader: some View {
        VStack(spacing: 8) {
            // Commander name with colors
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundColor(Constants.Colors.magicGold)

                Text(player.commanderName)
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textPrimary)

                Spacer()

                // Color identity
                HStack(spacing: 4) {
                    ForEach(player.colorIdentity, id: \.self) { color in
                        Circle()
                            .fill(Color.manaColor(for: color))
                            .frame(width: 20, height: 20)
                    }
                }
            }

            // Current life total
            Text("\(player.currentLife)")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(player.currentLife <= 10 ? Constants.Colors.warning : Constants.Colors.textPrimary)
                .monospacedDigit()
        }
        .padding()
        .background(Constants.Colors.backgroundSecondary)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ControlTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                    HapticManager.shared.selection()
                }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .foregroundColor(selectedTab == tab ? .black : Constants.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? Constants.Colors.magicGold : Color.clear)
                }
            }
        }
        .background(Constants.Colors.backgroundSecondary)
    }

    // MARK: - Life Controls

    private var lifeControls: some View {
        VStack(spacing: Constants.Layout.padding) {
            Text("Modifica Punti Vita")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textPrimary)

            // Quick adjust buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    QuickAdjustButton(amount: -10, color: Constants.Colors.lifeLoss) {
                        viewModel.changeLife(for: player, amount: -10)
                    }
                    QuickAdjustButton(amount: -5, color: Constants.Colors.lifeLoss) {
                        viewModel.changeLife(for: player, amount: -5)
                    }
                    QuickAdjustButton(amount: -1, color: Constants.Colors.lifeLoss) {
                        viewModel.changeLife(for: player, amount: -1)
                    }
                }

                HStack(spacing: 12) {
                    QuickAdjustButton(amount: 1, color: Constants.Colors.lifeGain) {
                        viewModel.changeLife(for: player, amount: 1)
                    }
                    QuickAdjustButton(amount: 5, color: Constants.Colors.lifeGain) {
                        viewModel.changeLife(for: player, amount: 5)
                    }
                    QuickAdjustButton(amount: 10, color: Constants.Colors.lifeGain) {
                        viewModel.changeLife(for: player, amount: 10)
                    }
                }
            }

            Divider()

            // Custom amount
            CustomAmountSection(title: "Importo Personalizzato") { amount in
                viewModel.changeLife(for: player, amount: amount)
                HapticManager.shared.lifeChange(amount: amount)
            }
        }
    }

    // MARK: - Commander Damage Controls

    private var commanderDamageControls: some View {
        VStack(spacing: Constants.Layout.padding) {
            Text("Danni da Comandante")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textPrimary)

            // For each opponent
            ForEach(viewModel.players.filter { $0.id != player.id }, id: \.id) { attacker in
                CommanderDamageRow(
                    attacker: attacker,
                    defender: player,
                    viewModel: viewModel
                )
            }
        }
    }

    // MARK: - Counter Controls

    private var counterControls: some View {
        VStack(spacing: Constants.Layout.padding) {
            // Poison
            CounterControlSection(
                title: "Poison Counter",
                symbol: Constants.Symbols.poison,
                currentValue: Int(player.poisonCounters),
                warningValue: Constants.GameRules.lethalPoison,
                color: Constants.Colors.poison
            ) { amount in
                viewModel.addPoisonCounters(to: player, amount: amount)
            }

            Divider()

            // Energy
            CounterControlSection(
                title: "Energy Counter",
                symbol: Constants.Symbols.energy,
                currentValue: Int(player.energyCounters),
                color: Constants.Colors.energy
            ) { amount in
                viewModel.addEnergyCounters(to: player, amount: amount)
            }

            Divider()

            // Experience
            CounterControlSection(
                title: "Experience Counter",
                symbol: Constants.Symbols.experience,
                currentValue: Int(player.experienceCounters),
                color: Constants.Colors.experience
            ) { amount in
                viewModel.addExperienceCounters(to: player, amount: amount)
            }
        }
    }

    // MARK: - Status Controls

    private var statusControls: some View {
        VStack(spacing: Constants.Layout.padding) {
            Text("Stati Speciali")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textPrimary)

            // Monarch
            StatusToggleRow(
                title: "Monarch",
                symbol: Constants.Symbols.monarch,
                isActive: player.hasMonarch
            ) {
                viewModel.setMonarch(player)
            }

            // Initiative
            StatusToggleRow(
                title: "Initiative",
                symbol: Constants.Symbols.initiative,
                isActive: player.hasInitiative
            ) {
                viewModel.setInitiative(player)
            }

            // Elimination status
            if player.isEliminated {
                VStack(spacing: 8) {
                    HStack {
                        Text(Constants.Symbols.eliminated)
                            .font(.title)
                        Text("Giocatore Eliminato")
                            .font(.headline)
                            .foregroundColor(Constants.Colors.lifeLoss)
                    }

                    if let reason = player.eliminationReason {
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                }
                .padding()
                .background(Constants.Colors.lifeLoss.opacity(0.2))
                .cornerRadius(Constants.Layout.cornerRadius)
            }
        }
    }
}

// MARK: - Supporting Views

/// Quick adjust button for life changes
struct QuickAdjustButton: View {
    let amount: Int
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(amount.signedString)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(color)
                .cornerRadius(Constants.Layout.smallCornerRadius)
        }
    }
}

/// Custom amount input section
struct CustomAmountSection: View {
    let title: String
    let onApply: (Int) -> Void

    @State private var customAmount: String = ""

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Constants.Colors.textSecondary)

            HStack {
                TextField("Importo", text: $customAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Constants.Colors.backgroundSecondary)
                    .cornerRadius(Constants.Layout.smallCornerRadius)
                    .foregroundColor(Constants.Colors.textPrimary)

                Button("Applica") {
                    if let amount = Int(customAmount) {
                        onApply(amount)
                        customAmount = ""
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Constants.Colors.magicGold)
                .foregroundColor(.black)
                .cornerRadius(Constants.Layout.smallCornerRadius)
            }
        }
    }
}

/// Commander damage row for a single attacker
struct CommanderDamageRow: View {
    let attacker: Player
    let defender: Player
    @ObservedObject var viewModel: GameViewModel

    private var currentDamage: Int {
        viewModel.getCommanderDamage(defender: defender, attacker: attacker)
    }

    private var isLethal: Bool {
        currentDamage >= Constants.GameRules.lethalCommanderDamage
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(attacker.commanderName)
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textPrimary)

                Spacer()

                Text("\(currentDamage)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isLethal ? Constants.Colors.lifeLoss : Constants.Colors.textSecondary)
                    .monospacedDigit()
            }

            // Quick buttons
            HStack(spacing: 8) {
                ForEach([1, 2, 3, 5, 10], id: \.self) { amount in
                    Button("+\(amount)") {
                        viewModel.applyCommanderDamage(from: attacker, to: defender, amount: amount)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Constants.Colors.backgroundSecondary)
                    .foregroundColor(Constants.Colors.textPrimary)
                    .cornerRadius(Constants.Layout.smallCornerRadius)
                }
            }
        }
        .padding()
        .background(Constants.Colors.backgroundSecondary)
        .cornerRadius(Constants.Layout.cornerRadius)
    }
}

/// Counter control section
struct CounterControlSection: View {
    let title: String
    let symbol: String
    let currentValue: Int
    var warningValue: Int? = nil
    let color: Color
    let onChange: (Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(symbol)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textPrimary)

                Spacer()

                Text("\(currentValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(
                        warningValue.map { currentValue >= $0 } ?? false
                            ? Constants.Colors.lifeLoss
                            : color
                    )
                    .monospacedDigit()
            }

            // Controls
            HStack(spacing: 8) {
                Button("-1") {
                    onChange(-1)
                }
                .buttonStyle(CounterButtonStyle(color: Constants.Colors.lifeLoss))
                .disabled(currentValue <= 0)

                Spacer()

                Button("+1") {
                    onChange(1)
                }
                .buttonStyle(CounterButtonStyle(color: color))

                Button("+3") {
                    onChange(3)
                }
                .buttonStyle(CounterButtonStyle(color: color))

                Button("+5") {
                    onChange(5)
                }
                .buttonStyle(CounterButtonStyle(color: color))
            }
        }
    }
}

/// Status toggle row
struct StatusToggleRow: View {
    let title: String
    let symbol: String
    let isActive: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(symbol)
                    .font(.title2)

                Text(title)
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textPrimary)

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Constants.Colors.success)
                        .font(.title3)
                }
            }
            .padding()
            .background(isActive ? Constants.Colors.magicGold.opacity(0.2) : Constants.Colors.backgroundSecondary)
            .cornerRadius(Constants.Layout.cornerRadius)
        }
    }
}

/// Counter button style
struct CounterButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(Constants.Layout.smallCornerRadius)
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let session = controller.fetchActiveSessions().first!
    let viewModel = GameViewModel(session: session)

    return PlayerDetailSheet(
        player: session.playersArray[0],
        viewModel: viewModel
    )
}

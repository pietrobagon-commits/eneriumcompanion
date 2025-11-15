//
//  ActionLogView.swift
//  CommanderScorekeeper
//
//  Complete action log view.
//  Displays chronological history of all game actions.
//

import SwiftUI

struct ActionLogView: View {

    // MARK: - Properties

    let actions: [GameAction]

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundPrimary
                    .ignoresSafeArea()

                if actions.isEmpty {
                    emptyState
                } else {
                    actionsList
                }
            }
            .navigationTitle("Log Azioni")
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.textDisabled)

            Text("Nessuna azione registrata")
                .font(.headline)
                .foregroundColor(Constants.Colors.textSecondary)

            Text("Le azioni di gioco appariranno qui")
                .font(.caption)
                .foregroundColor(Constants.Colors.textDisabled)
        }
    }

    // MARK: - Actions List

    private var actionsList: some View {
        List {
            ForEach(actions) { action in
                ActionRow(action: action)
                    .listRowBackground(Constants.Colors.backgroundSecondary)
                    .listRowSeparatorTint(Constants.Colors.backgroundPrimary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Action Row

struct ActionRow: View {
    let action: GameAction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(action.timestamp.timeString)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
                    .monospacedDigit()

                Text(action.timestamp.relativeTimeString)
                    .font(.caption2)
                    .foregroundColor(Constants.Colors.textDisabled)
            }
            .frame(width: 80, alignment: .leading)

            // Icon
            actionIcon
                .frame(width: 30)

            // Description
            VStack(alignment: .leading, spacing: 4) {
                Text(action.actionDescription)
                    .font(.body)
                    .foregroundColor(Constants.Colors.textPrimary)

                if action.value != 0 {
                    Text("Valore: \(action.value)")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var actionIcon: some View {
        let config = iconConfiguration

        Image(systemName: config.icon)
            .font(.title3)
            .foregroundColor(config.color)
    }

    private var iconConfiguration: (icon: String, color: Color) {
        switch action.type {
        case .lifeChange:
            return action.value > 0
                ? ("heart.fill", Constants.Colors.lifeGain)
                : ("heart.slash.fill", Constants.Colors.lifeLoss)

        case .commanderDamage:
            return ("hammer.fill", Constants.Colors.lifeLoss)

        case .poisonCounter:
            return ("drop.fill", Constants.Colors.poison)

        case .energyCounter:
            return ("bolt.fill", Constants.Colors.energy)

        case .experienceCounter:
            return ("star.fill", Constants.Colors.experience)

        case .monarchChange:
            return ("crown.fill", Constants.Colors.magicGold)

        case .initiativeChange:
            return ("dice.fill", Constants.Colors.info)

        case .playerElimination:
            return ("xmark.circle.fill", Constants.Colors.lifeLoss)

        case .gameStart:
            return ("play.circle.fill", Constants.Colors.success)

        case .gameEnd:
            return ("stop.circle.fill", Constants.Colors.warning)
        }
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let session = controller.fetchActiveSessions().first!

    return ActionLogView(actions: session.actionsArray)
}

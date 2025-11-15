//
//  GameSessionRow.swift
//  CommanderScorekeeper
//
//  Row view for a saved game session.
//  Displays session info, players, and current status.
//

import SwiftUI

struct GameSessionRow: View {

    // MARK: - Properties

    let session: GameSession

    private var players: [Player] {
        session.playersArray
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: date and status
            HStack {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.startDate.shortDateTimeString)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)

                    Text(session.startDate.relativeTimeString)
                        .font(.caption2)
                        .foregroundColor(Constants.Colors.textDisabled)
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Players grid
            playersGrid

            // Footer: duration and winner
            HStack {
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text(session.formattedDuration)
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(Constants.Colors.textSecondary)

                Spacer()

                // Winner (if game ended)
                if let winner = session.winner {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.magicGold)
                        Text(winner.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Constants.Colors.magicGold)
                    }
                }
            }
        }
        .padding()
        .background(Constants.Colors.backgroundSecondary)
        .cornerRadius(Constants.Layout.cornerRadius)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Group {
            if session.isActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Constants.Colors.success)
                        .frame(width: 8, height: 8)
                    Text("In corso")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Constants.Colors.success)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Constants.Colors.success.opacity(0.2))
                .cornerRadius(Constants.Layout.smallCornerRadius)
            } else {
                Text("Terminata")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Constants.Colors.textDisabled)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Constants.Colors.textDisabled.opacity(0.2))
                    .cornerRadius(Constants.Layout.smallCornerRadius)
            }
        }
    }

    // MARK: - Players Grid

    private var playersGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(players, id: \.id) { player in
                PlayerPreviewCard(player: player)
            }
        }
    }
}

// MARK: - Player Preview Card

struct PlayerPreviewCard: View {
    let player: Player

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Name
            Text(player.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.textPrimary)
                .lineLimit(1)

            // Life total
            HStack(spacing: 4) {
                Image(systemName: player.isEliminated ? "heart.slash.fill" : "heart.fill")
                    .font(.caption2)
                    .foregroundColor(player.isEliminated ? Constants.Colors.lifeLoss : lifeColor)

                Text("\(player.currentLife)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(player.isEliminated ? Constants.Colors.lifeLoss : lifeColor)
                    .monospacedDigit()
            }

            // Commander
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.caption2)
                    .foregroundColor(Constants.Colors.magicGold)

                Text(player.commanderName)
                    .font(.caption2)
                    .foregroundColor(Constants.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // Color identity
            HStack(spacing: 2) {
                ForEach(player.colorIdentity, id: \.self) { color in
                    Circle()
                        .fill(Color.manaColor(for: color))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Constants.Colors.backgroundPrimary)
        .cornerRadius(Constants.Layout.smallCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius)
                .strokeBorder(
                    player.isEliminated
                        ? Constants.Colors.textDisabled
                        : Color.gradientForColorIdentity(player.colorIdentity),
                    lineWidth: 1
                )
        )
        .opacity(player.isEliminated ? 0.6 : 1.0)
    }

    private var lifeColor: Color {
        if player.currentLife <= 0 {
            return Constants.Colors.lifeLoss
        } else if player.currentLife <= 10 {
            return Constants.Colors.warning
        } else {
            return Constants.Colors.textPrimary
        }
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let session = controller.fetchActiveSessions().first!

    return List {
        GameSessionRow(session: session)
            .listRowBackground(Constants.Colors.backgroundSecondary)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Constants.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}

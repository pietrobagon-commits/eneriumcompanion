//
//  PlayerQuadrant.swift
//  CommanderScorekeeper
//
//  Individual player quadrant view.
//  Displays life total, commander damage, counters, and status.
//

import SwiftUI

struct PlayerQuadrant: View {

    // MARK: - Properties

    let player: Player
    @ObservedObject var viewModel: GameViewModel
    let rotation: Angle

    private var flashState: (isActive: Bool, isDamage: Bool) {
        viewModel.getFlashState(for: player)
    }

    private var otherPlayers: [Player] {
        viewModel.players.filter { $0.id != player.id }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background with damage flash
            Constants.Colors.backgroundSecondary
                .overlay(
                    Rectangle()
                        .fill(flashState.isDamage ? Constants.Colors.lifeLoss : Constants.Colors.lifeGain)
                        .opacity(flashState.isActive ? 0.3 : 0)
                        .animation(.easeOut(duration: Constants.Animation.damageFlashDuration), value: flashState.isActive)
                )

            // Content
            VStack(spacing: 8) {
                // Player name and commander
                playerHeader

                Spacer()

                // Life total (BIG)
                lifeDisplay

                Spacer()

                // Commander damage received
                commanderDamageSection

                // Secondary counters
                if hasSecondaryCounters {
                    secondaryCountersSection
                }

                // Status icons
                if player.hasMonarch || player.hasInitiative {
                    statusIconsSection
                }
            }
            .padding(12)
            .rotationEffect(rotation)

            // Eliminated overlay
            if player.isEliminated {
                eliminatedOverlay
            }
        }
        .playerQuadrantStyle(colorIdentity: player.colorIdentity, isEliminated: player.isEliminated)
    }

    // MARK: - Player Header

    private var playerHeader: some View {
        VStack(spacing: 4) {
            // Player name
            Text(player.name)
                .font(.system(size: Constants.Layout.playerNameFontSize, weight: .bold))
                .foregroundColor(Constants.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Commander name
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.caption2)
                    .foregroundColor(Constants.Colors.magicGold)

                Text(player.commanderName)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // Color identity symbols
            HStack(spacing: 2) {
                ForEach(player.colorIdentity, id: \.self) { color in
                    Circle()
                        .fill(Color.manaColor(for: color))
                        .frame(width: 12, height: 12)
                }
            }
        }
    }

    // MARK: - Life Display

    private var lifeDisplay: some View {
        Text("\(player.currentLife)")
            .font(.system(size: Constants.Layout.lifeFontSize, weight: .bold, design: .rounded))
            .foregroundColor(lifeColor)
            .monospacedDigit()
            .shadow(color: .black.opacity(0.5), radius: 4)
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

    // MARK: - Commander Damage

    private var commanderDamageSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(otherPlayers, id: \.id) { attacker in
                let damage = viewModel.getCommanderDamage(defender: player, attacker: attacker)

                if damage > 0 {
                    HStack(spacing: 4) {
                        Text(Constants.Symbols.commanderDamage)
                            .font(.caption2)

                        Text("\(attacker.commanderName): \(damage)")
                            .font(.system(size: Constants.Layout.commanderDamageFontSize, weight: .medium))
                            .foregroundColor(
                                viewModel.isCommanderDamageLethal(defender: player, attacker: attacker)
                                    ? Constants.Colors.lifeLoss
                                    : Constants.Colors.textSecondary
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Secondary Counters

    private var hasSecondaryCounters: Bool {
        player.poisonCounters > 0 || player.energyCounters > 0 || player.experienceCounters > 0
    }

    private var secondaryCountersSection: some View {
        HStack(spacing: 12) {
            if player.poisonCounters > 0 {
                CounterBadge(
                    symbol: Constants.Symbols.poison,
                    value: Int(player.poisonCounters),
                    color: player.poisonCounters >= 10 ? Constants.Colors.lifeLoss : Constants.Colors.poison
                )
            }

            if player.energyCounters > 0 {
                CounterBadge(
                    symbol: Constants.Symbols.energy,
                    value: Int(player.energyCounters),
                    color: Constants.Colors.energy
                )
            }

            if player.experienceCounters > 0 {
                CounterBadge(
                    symbol: Constants.Symbols.experience,
                    value: Int(player.experienceCounters),
                    color: Constants.Colors.experience
                )
            }
        }
    }

    // MARK: - Status Icons

    private var statusIconsSection: some View {
        HStack(spacing: 8) {
            if player.hasMonarch {
                Text(Constants.Symbols.monarch)
                    .font(.title3)
            }

            if player.hasInitiative {
                Text(Constants.Symbols.initiative)
                    .font(.title3)
            }
        }
    }

    // MARK: - Eliminated Overlay

    private var eliminatedOverlay: some View {
        ZStack {
            Constants.Colors.eliminated

            VStack(spacing: 8) {
                Text(Constants.Symbols.eliminated)
                    .font(.system(size: 60))

                Text("ELIMINATO")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.textPrimary)

                if let reason = player.eliminationReason {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .rotationEffect(rotation)
        }
    }
}

// MARK: - Counter Badge

struct CounterBadge: View {
    let symbol: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(symbol)
                .font(.caption2)
            Text("\(value)")
                .font(.system(size: Constants.Layout.counterFontSize, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .cornerRadius(Constants.Layout.smallCornerRadius)
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let session = controller.fetchActiveSessions().first!
    let viewModel = GameViewModel(session: session)

    return PlayerQuadrant(
        player: session.playersArray[0],
        viewModel: viewModel,
        rotation: .degrees(0)
    )
    .frame(width: 400, height: 300)
    .preferredColorScheme(.dark)
}

//
//  View+Extensions.swift
//  CommanderScorekeeper
//
//  SwiftUI View extensions for common modifiers and utilities.
//

import SwiftUI

extension View {

    // MARK: - Card Style

    /// Apply Magic card-style border and shadow
    func magicCardStyle(borderColors: [Color] = [Constants.Colors.magicGold]) -> some View {
        self
            .background(Constants.Colors.backgroundSecondary)
            .cornerRadius(Constants.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Constants.Layout.borderWidth
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: Constants.Layout.shadowRadius, x: 0, y: 4)
    }

    /// Apply player quadrant style with color identity border
    func playerQuadrantStyle(colorIdentity: [String], isEliminated: Bool = false) -> some View {
        let borderColors = colorIdentity.isEmpty
            ? [Constants.Colors.colorless]
            : colorIdentity.map { Color.manaColor(for: $0) }

        return self
            .background(Constants.Colors.backgroundSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isEliminated ? Constants.Layout.eliminatedBorderWidth : Constants.Layout.borderWidth
                    )
            )
            .opacity(isEliminated ? 0.5 : 1.0)
    }

    // MARK: - Conditional Modifiers

    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply different modifiers based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    // MARK: - Glow Effects

    /// Add a glow effect with specified color
    func glow(color: Color, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius * 0.7, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 0.4, x: 0, y: 0)
    }

    /// Add a pulsing glow animation
    func pulsingGlow(color: Color, radius: CGFloat = 20) -> some View {
        self.modifier(PulsingGlowModifier(color: color, radius: radius))
    }

    // MARK: - Damage Flash

    /// Flash effect for damage/life changes
    func damageFlash(isActive: Bool, isDamage: Bool) -> some View {
        self.modifier(DamageFlashModifier(isActive: isActive, isDamage: isDamage))
    }

    // MARK: - Shimmer Effect

    /// Add shimmer animation (useful for loading states)
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }

    // MARK: - Accessibility

    /// Add comprehensive accessibility support
    func accessibleButton(label: String, hint: String? = nil, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .if(value != nil) { view in
                view.accessibilityValue(value!)
            }
            .accessibilityAddTraits(.isButton)
    }

    /// Add value accessibility
    func accessibleValue(_ value: String, label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
    }
}

// MARK: - Custom View Modifiers

/// Pulsing glow modifier
struct PulsingGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .glow(color: color, radius: isPulsing ? radius : radius * 0.5)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// Damage flash modifier
struct DamageFlashModifier: ViewModifier {
    let isActive: Bool
    let isDamage: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(isDamage ? Constants.Colors.lifeLoss : Constants.Colors.lifeGain)
                    .opacity(isActive ? 0.3 : 0)
                    .animation(.easeOut(duration: Constants.Animation.damageFlashDuration), value: isActive)
            )
    }
}

/// Shimmer modifier for loading states
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

// MARK: - Number Formatting Extensions

extension Int {
    /// Format life total with + or - prefix
    var signedString: String {
        self >= 0 ? "+\(self)" : "\(self)"
    }

    /// Format as localized string with thousands separator
    var formattedString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Int32 {
    /// Format life total with + or - prefix
    var signedString: String {
        Int(self).signedString
    }

    /// Format as localized string with thousands separator
    var formattedString: String {
        Int(self).formattedString
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format as relative time (e.g., "2 minuti fa")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Format as short date and time
    var shortDateTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Format as time only (HH:mm)
    var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Binding Extensions

extension Binding {
    /// Create a binding that logs changes
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

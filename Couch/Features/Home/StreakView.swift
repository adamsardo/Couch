import SwiftUI

struct StreakView: View {
    let days: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: CouchTheme.Spacing.md) {
            flame
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.xxs) {
                Label("Momentum", systemImage: "flame")
                    .labelStyle(.titleOnly)
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.accent)
                Text(streakTitle)
                    .font(CouchTheme.Typography.cardTitle.monospacedDigit())
                    .foregroundStyle(CouchTheme.textPrimary)
                    .contentTransition(.numericText())
                Text(subtitle)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .couchGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(streakAccessibilityLabel)
    }

    private var flame: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(CouchTheme.accent)
            .symbolEffect(
                .variableColor.iterative.reversing,
                options: .repeating,
                isActive: days > 0 && !reduceMotion
            )
            .symbolEffect(.bounce, value: days)
            .accessibilityHidden(true)
    }

    private var streakTitle: String {
        days == 0 ? "Today is the start." : "\(days)-day streak"
    }

    private var streakAccessibilityLabel: String {
        days == 0 ? "Momentum. Today is the start." : "Momentum. \(days) day streak."
    }

    private var subtitle: String {
        switch days {
        case 0: return "One rep tonight is enough."
        case 1: return "Day one. The compounding starts now."
        case 2...4: return "Reps stack faster than you think."
        default: return "You've made this a habit."
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StreakView(days: 0)
        StreakView(days: 1)
        StreakView(days: 7)
    }
    .padding()
    .background(CouchTheme.background)
}

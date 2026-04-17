import SwiftUI

struct StreakView: View {
    let days: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Momentum", systemImage: "flame.fill")
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.accent)
            Text(days == 0 ? "Today is the start." : "\(days)-day streak")
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.textPrimary)
            Text(subtitle)
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .couchGlassCard()
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

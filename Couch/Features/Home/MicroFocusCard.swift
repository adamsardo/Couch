import SwiftUI

struct MicroFocusCard: View {
    let title: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Label("Carry into your next rep", systemImage: "target")
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.accent)
            Text(title.isEmpty ? "Pick a focus next time" : title)
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.textPrimary)
            if !bodyText.isEmpty {
                Text(bodyText)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .couchGlassCard(tint: CouchTheme.accent.opacity(0.08))
    }
}

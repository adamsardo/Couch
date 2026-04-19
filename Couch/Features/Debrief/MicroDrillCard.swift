import SwiftUI

struct MicroDrillCard: View {
    let payload: MicroDrillPayload

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
            Label("Micro-drill", systemImage: "target")
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.accentOnLight)
            Text(payload.title)
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
            Text(payload.body)
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .couchGlassCard(tint: CouchTheme.accent.opacity(0.12))
        .accessibilityElement(children: .combine)
    }
}

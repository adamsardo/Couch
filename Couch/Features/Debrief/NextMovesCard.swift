import SwiftUI

struct NextMovesCard: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
            Label("Next moves", systemImage: "arrow.up.right.circle.fill")
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.primary)
            ForEach(Array(items.enumerated()), id: \.offset) { index, move in
                HStack(alignment: .top, spacing: CouchTheme.Spacing.sm + 2) {
                    Text("\(index + 1)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(CouchTheme.surface)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(CouchTheme.primary))
                        .accessibilityHidden(true)
                    Text(move)
                        .font(CouchTheme.Typography.body)
                        .foregroundStyle(CouchTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .couchGlassCard(tint: CouchTheme.primary.opacity(0.08))
        .accessibilityElement(children: .combine)
    }
}

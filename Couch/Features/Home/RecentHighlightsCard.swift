import SwiftUI

struct RecentHighlightsCard: View {
    let strengths: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Label("Recent highlights", systemImage: "bookmark.fill")
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.success)
            ForEach(Array(strengths.prefix(3).enumerated()), id: \.offset) { _, strength in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CouchTheme.success)
                        .frame(width: 18)
                    Text(strength)
                        .font(CouchTheme.Typography.body)
                        .foregroundStyle(CouchTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .couchGlassCard()
    }
}

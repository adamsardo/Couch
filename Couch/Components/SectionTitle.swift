import SwiftUI

struct SectionTitle: View {
    let text: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(CouchTheme.Typography.sectionTitle)
                .foregroundStyle(CouchTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

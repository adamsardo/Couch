import SwiftUI

/// Compact scenario summary used on scenario detail and session intro.
/// Keeps the disclosure readable without decorative symbols competing with
/// the clinical content.
struct SubtitlePill: View {
    let title: String
    let subtitle: String
    /// Outer corner radius of the container this pill sits in. The pill's
    /// own radius is derived concentrically so nested shapes track each
    /// other (`visual-concentric-radius`).
    var outerRadius: CGFloat = CouchTheme.Radius.card
    /// Padding from the outer card to this pill. Used to derive the
    /// concentric inner radius.
    var outerPadding: CGFloat = CouchTheme.Spacing.lg

    var body: some View {
        HStack(alignment: .center, spacing: CouchTheme.Spacing.sm) {
            Image(systemName: CouchIcons.shieldCheck)
                .font(.callout.weight(.semibold))
                .foregroundStyle(CouchTheme.primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(CouchTheme.primarySoft.opacity(0.65)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.xxs) {
                Text(title)
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(CouchTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, CouchTheme.Spacing.sm + 2)
        .padding(.horizontal, CouchTheme.Spacing.md)
        .background(
            RoundedRectangle(
                cornerRadius: CouchTheme.Radius.inner(of: outerRadius, padding: outerPadding),
                style: .continuous
            )
            .fill(CouchTheme.surfaceMuted)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SubtitlePill(
        title: "Opening up around trust",
        subtitle: "Virtual patient. Practice, not therapy."
    )
    .padding()
    .background(CouchTheme.background)
}

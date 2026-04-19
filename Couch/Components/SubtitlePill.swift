import SwiftUI

/// Editorial subtitle pill with decorative leaf accents on either side.
/// Used on the scenario detail and session intro to frame the scenario's
/// title + "AI-simulated patient" disclosure line.
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
            leafAccent(flipped: false)

            VStack(alignment: .center, spacing: CouchTheme.Spacing.xxs) {
                Text(title)
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(CouchTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            leafAccent(flipped: true)
        }
        .padding(.vertical, CouchTheme.Spacing.md)
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

    private func leafAccent(flipped: Bool) -> some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(CouchTheme.primary.opacity(0.6))
            .rotationEffect(.degrees(flipped ? 30 : -30))
            .scaleEffect(x: flipped ? -1 : 1, y: 1)
            .accessibilityHidden(true)
    }
}

#Preview {
    SubtitlePill(
        title: "First-session intake",
        subtitle: "AI-simulated patient. Not a real person."
    )
    .padding()
    .background(CouchTheme.background)
}

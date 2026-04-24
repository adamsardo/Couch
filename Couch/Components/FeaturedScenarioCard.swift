import SwiftUI

/// Primary home card for the next practice rep. The portrait and text are
/// separated so copy stays readable and the patient art does not have to carry
/// a heavy scrim.
struct FeaturedScenarioCard: View {
    let scenario: Scenario
    var ctaTitle: String = "Run rep"
    var subtitle: String? = nil
    var onStart: () -> Void

    var body: some View {
        Button {
            CouchHaptics.tap()
            onStart()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ScenarioPortraitView(
                    scenario: scenario,
                    crop: .topFocused,
                    overlays: []
                )
                .frame(height: 228)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: CouchTheme.Radius.card,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: CouchTheme.Radius.card,
                        style: .continuous
                    )
                )
                .overlay(alignment: .topLeading) {
                    HStack(spacing: CouchTheme.Spacing.xs) {
                        chip(icon: CouchIcons.people, text: "Virtual patient")
                        chip(icon: CouchIcons.clock, text: "~10 min")
                    }
                    .padding(CouchTheme.Spacing.md)
                }

                VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                    Text("Opening up around trust")
                        .font(CouchTheme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .kerning(1.1)
                        .foregroundStyle(CouchTheme.primary)
                    Text(scenario.patientName)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(CouchTheme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(CouchTheme.Typography.body)
                            .foregroundStyle(CouchTheme.textSecondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: CouchTheme.Spacing.sm) {
                        ctaLabel
                        Spacer(minLength: 0)
                        Image(systemName: CouchIcons.arrowRight)
                            .font(.callout.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(CouchTheme.primary))
                    }
                    .padding(.top, CouchTheme.Spacing.xs)
                }
                .padding(CouchTheme.Spacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.card, style: .continuous)
                    .fill(CouchTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.card, style: .continuous)
                    .strokeBorder(CouchTheme.divider, lineWidth: 1)
            )
            .couchElevation(.md)
        }
        .buttonStyle(.couchPress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Run rep with \(scenario.patientName)")
    }

    private var ctaLabel: some View {
        HStack(spacing: CouchTheme.Spacing.xs) {
            Image(systemName: CouchIcons.playFill)
                .font(.footnote.weight(.bold))
                .foregroundStyle(CouchTheme.primary)
            Text(ctaTitle)
                .font(CouchTheme.Typography.pill)
                .foregroundStyle(CouchTheme.textPrimary)
        }
        .padding(.horizontal, CouchTheme.Spacing.md)
        .padding(.vertical, CouchTheme.Spacing.xs + 2)
        .background(Capsule().fill(CouchTheme.primarySoft.opacity(0.58)))
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(CouchTheme.Typography.caption.weight(.semibold))
        }
        .foregroundStyle(CouchTheme.textPrimary)
        .padding(.horizontal, CouchTheme.Spacing.sm)
        .padding(.vertical, CouchTheme.Spacing.xxs + 1)
        .background(Capsule().fill(CouchTheme.surface.opacity(0.88)))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.55), lineWidth: 1))
    }
}

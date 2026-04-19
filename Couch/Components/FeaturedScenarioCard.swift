import SwiftUI

/// Large hero-style home card. Scenario portrait fills the card with a
/// bottom scrim; the scenario name, AI-patient disclosure, and a primary
/// CTA sit on the scrim. Occupies the full card slot on Home and drives
/// the primary "start a rep" entry point.
struct FeaturedScenarioCard: View {
    let scenario: Scenario
    var ctaTitle: String = "Start rep"
    var subtitle: String? = nil
    var onStart: () -> Void

    var body: some View {
        Button {
            CouchHaptics.tap()
            onStart()
        } label: {
            ZStack(alignment: .bottomLeading) {
                ScenarioPortraitView(
                    scenario: scenario,
                    crop: .topFocused,
                    overlays: [.bottomScrim]
                )
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: CouchTheme.Radius.sheet, style: .continuous))

                VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                    HStack(spacing: CouchTheme.Spacing.xs) {
                        chip(icon: CouchIcons.sparkles, text: "AI patient")
                        chip(icon: CouchIcons.clock, text: "~10 min")
                    }
                    Text(scenario.patientName)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(CouchTheme.Typography.body)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    HStack {
                        ctaLabel
                        Spacer(minLength: 0)
                        playBadge
                    }
                }
                .padding(CouchTheme.Spacing.lg)
            }
        }
        .buttonStyle(.couchPress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Start rep with \(scenario.patientName)")
    }

    private var ctaLabel: some View {
        HStack(spacing: CouchTheme.Spacing.xs) {
            Image(systemName: CouchIcons.playFill)
                .font(.footnote.weight(.bold))
                .foregroundStyle(CouchTheme.textPrimary)
            Text(ctaTitle)
                .font(CouchTheme.Typography.pill)
                .foregroundStyle(CouchTheme.textPrimary)
        }
        .padding(.horizontal, CouchTheme.Spacing.md)
        .padding(.vertical, CouchTheme.Spacing.xs + 2)
        .background(Capsule().fill(.white))
    }

    private var playBadge: some View {
        Image(systemName: CouchIcons.arrowRight)
            .font(.callout.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(.white.opacity(0.18)))
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(CouchTheme.Typography.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, CouchTheme.Spacing.sm)
        .padding(.vertical, CouchTheme.Spacing.xxs + 1)
        .background(Capsule().fill(.white.opacity(0.24)))
    }
}

import SwiftUI

/// Editorial session-intro screen. Full-bleed portrait hero, eyebrow +
/// wrapped title (no more `…wit…` truncation), SubtitlePill, italic quote,
/// compact chip strip, and a pinned primary CTA via `safeAreaInset`.
struct SessionIntroView: View {
    let scenario: Scenario
    /// Namespace for zoom navigation transitions. The CTA becomes the
    /// `matchedTransitionSource`; the presenting container's conversation
    /// view calls `.navigationTransition(.zoom(sourceID: "session-start", in: namespace))`.
    var transitionNamespace: Namespace.ID?
    var onBack: (() -> Void)? = nil
    var onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                    .containerRelativeFrame(.vertical) { length, _ in length * 0.58 }

                sheetCard
                    .offset(y: -CouchTheme.Radius.sheet)
                    .padding(.bottom, -CouchTheme.Radius.sheet)
            }
        }
        .scrollIndicators(.hidden)
        .background(CouchTheme.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) {
            startButton
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .padding(.vertical, CouchTheme.Spacing.md)
                .background(CouchTheme.background.opacity(0.98))
        }
        .overlay(alignment: .topLeading) {
            if let onBack {
                FloatingBackButton(action: onBack)
                    .padding(.leading, CouchTheme.Spacing.md)
                    .padding(.top, CouchTheme.Spacing.sm)
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        ScenarioPortraitView(
            scenario: scenario,
            crop: .topFocused,
            overlays: [.bottomScrim]
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sheet card

    private var sheetCard: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            eyebrow
            title
            SubtitlePill(
                title: scenario.title.capitalized,
                subtitle: "AI-simulated patient. Not a real person.",
                outerRadius: CouchTheme.Radius.sheet,
                outerPadding: CouchTheme.Spacing.lg
            )
            quote
            previewTiles
        }
        .padding(.horizontal, CouchTheme.Spacing.lg)
        .padding(.top, CouchTheme.Spacing.lg)
        .padding(.bottom, CouchTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: CouchTheme.Radius.sheet,
                topTrailingRadius: CouchTheme.Radius.sheet,
                style: .continuous
            )
            .fill(CouchTheme.background)
        )
    }

    private var eyebrow: some View {
        Text("SESSION 1 · FIRST REP")
            .font(CouchTheme.Typography.eyebrow)
            .textCase(.uppercase)
            .kerning(1.2)
            .foregroundStyle(CouchTheme.textMuted)
            .accessibilityLabel("Session 1, first rep")
    }

    private var title: some View {
        Text("Warm-up with \(scenario.patientName)")
            .font(CouchTheme.Typography.display)
            .foregroundStyle(CouchTheme.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var quote: some View {
        Text("\u{201C}\(scenario.openingCue)\u{201D}")
            .font(CouchTheme.Typography.body)
            .italic()
            .foregroundStyle(CouchTheme.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// Stat-tile strip previewing what to expect from the rep. Keeps the
    /// intro card glance-readable on narrow widths.
    private var previewTiles: some View {
        HStack(spacing: CouchTheme.Spacing.sm) {
            StatTile(value: "~10", caption: "Minutes")
            StatTile(value: "~12", caption: "Turns")
            StatTile(value: "3", caption: "Next moves")
        }
    }

    // MARK: - CTA

    @ViewBuilder
    private var startButton: some View {
        let button = PrimaryButton(title: "Start conversation", systemImage: "play.fill") {
            onStart()
        }
        if let ns = transitionNamespace {
            button.matchedTransitionSource(id: "session-start", in: ns)
        } else {
            button
        }
    }
}

#Preview {
    let scenario = Scenario(
        id: "marcus-intake",
        title: "First-session intake",
        patientName: "Marcus",
        patientAge: 28,
        summary: "His partner referred him. He doesn't want to be here. Stay curious, stay calm.",
        openingCue: "Marcus walks in, sits down without a word, and waits for you to start.",
        calmingCue: "Take a breath. Curiosity, not certainty.",
        elevenLabsAgentId: ""
    )
    return SessionIntroView(scenario: scenario, onStart: {})
}

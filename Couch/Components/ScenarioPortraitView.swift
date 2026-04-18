import SwiftUI

/// Single entry point for rendering a scenario's portrait. Loads the
/// bundled `scenario-<id>` imageset when available and falls back to a
/// premium gradient + monogram + soft vignette so the UI never collapses
/// to a "cheap big letter" look while art is in flight.
///
/// Shared by the intro hero, the in-call full-bleed background, the
/// onboarding detail hero, the home avatar ring, and the scenario-match
/// cards — so all five surfaces stay visually consistent.
struct ScenarioPortraitView: View {
    /// Where the portrait is being used dictates crop behavior.
    enum Crop: Equatable {
        /// Full-bleed, center-anchored. Used for the in-call background.
        case full
        /// Full-bleed, top-anchored so the subject's eyes sit in the
        /// upper third regardless of container height. Used for the
        /// intro hero where the card overlaps the bottom.
        case topFocused
        /// Circular avatar at the given diameter. Used for the home
        /// avatar ring and the settings profile row.
        case avatar(CGFloat)
    }

    /// Which gradients/vignettes to layer over the photo.
    struct Overlays: OptionSet {
        let rawValue: Int
        static let topScrim = Overlays(rawValue: 1 << 0)
        static let bottomScrim = Overlays(rawValue: 1 << 1)
        static let vignette = Overlays(rawValue: 1 << 2)
    }

    let scenario: Scenario
    var crop: Crop = .full
    var overlays: Overlays = []

    var body: some View {
        switch crop {
        case .full:
            rectangularPortrait(anchor: .center)
        case .topFocused:
            rectangularPortrait(anchor: .top)
        case .avatar(let diameter):
            avatarPortrait(diameter: diameter)
        }
    }

    // MARK: - Rectangular (hero / full-bleed) variants

    @ViewBuilder
    private func rectangularPortrait(anchor: UnitPoint) -> some View {
        ZStack {
            if let image = resolvedImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackGradient
                    .drawingGroup()
            }

            if overlays.contains(.vignette) {
                RadialGradient(
                    colors: [.clear, .black.opacity(0.22)],
                    center: .center,
                    startRadius: 140,
                    endRadius: 420
                )
                .blendMode(.multiply)
                .allowsHitTesting(false)
            }

            if overlays.contains(.topScrim) {
                LinearGradient(
                    colors: [.black.opacity(0.45), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .allowsHitTesting(false)
            }

            if overlays.contains(.bottomScrim) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: anchor == .top ? .top : .center)
        .clipped()
        .accessibilityLabel(Text("Portrait of \(scenario.patientName)"))
    }

    // MARK: - Avatar variant

    @ViewBuilder
    private func avatarPortrait(diameter: CGFloat) -> some View {
        ZStack {
            if let image = resolvedImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackGradient
                Text(String(scenario.patientName.prefix(1)))
                    .font(.system(size: diameter * 0.45, weight: .bold, design: .rounded))
                    .foregroundStyle(CouchTheme.textPrimary.opacity(0.45))
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .accessibilityLabel(Text("\(scenario.patientName) avatar"))
    }

    // MARK: - Resolution + fallback

    private var resolvedImage: Image? {
        let assetName = "scenario-\(scenario.id)"
        return UIImage(named: assetName).map { _ in Image(assetName) }
    }

    /// Warm-neutral gradient + soft monogram. Keeps fallback readable on
    /// both light sheet cards and full-bleed dark call backgrounds.
    @ViewBuilder
    private var fallbackGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CouchTheme.callSurfaceMuted,
                    CouchTheme.callSurface
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    CouchTheme.primary.opacity(0.08),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(String(scenario.patientName.prefix(1)))
                .font(.system(size: 180, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.08))
        }
    }
}

#Preview {
    let scenario = Scenario(
        id: "marcus-intake",
        title: "First-session intake",
        patientName: "Marcus",
        patientAge: 28,
        summary: "His partner referred him.",
        openingCue: "Marcus walks in and waits.",
        calmingCue: "Curiosity, not certainty.",
        elevenLabsAgentId: ""
    )
    return VStack(spacing: 16) {
        ScenarioPortraitView(
            scenario: scenario,
            crop: .topFocused,
            overlays: [.bottomScrim]
        )
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

        HStack(spacing: 16) {
            ScenarioPortraitView(scenario: scenario, crop: .avatar(60))
            ScenarioPortraitView(scenario: scenario, crop: .avatar(48))
        }
    }
    .padding()
    .background(CouchTheme.background)
}

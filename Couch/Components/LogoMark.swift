import SwiftUI

/// Brand logomark used on the splash screen and anywhere the app wants to
/// introduce itself. Two variants:
/// - `.pill` — rounded capsule with the wordmark inside (splash, onboarding intro).
/// - `.mark` — just the inner circular glyph (inline, tab-bar accessory).
///
/// The glyph is a concentric ring-in-circle built with `Shape` primitives so
/// it stays crisp at any size and renders without needing a bundled asset.
struct LogoMark: View {
    enum Style: Equatable {
        case pill
        case mark
    }

    var style: Style = .pill
    var height: CGFloat = 120
    var tint: Color = .white
    var accent: Color = CouchTheme.primary

    var body: some View {
        switch style {
        case .pill:
            pillBody
        case .mark:
            markBody
        }
    }

    private var pillBody: some View {
        HStack(spacing: height * 0.02) {
            glyph(diameter: height * 0.82)
                .offset(x: height * 0.02)
            glyphBar(diameter: height * 0.82)
                .offset(x: -height * 0.02)
        }
        .frame(width: height * 1.7, height: height)
        .padding(.horizontal, height * 0.18)
        .padding(.vertical, height * 0.08)
        .background(
            Capsule(style: .continuous)
                .strokeBorder(tint, lineWidth: max(3, height * 0.04))
        )
        .accessibilityLabel("Couch")
    }

    private var markBody: some View {
        glyph(diameter: height)
            .accessibilityLabel("Couch")
    }

    /// The left "O" — an open ring with a gap filled by a wordmark-like bar.
    private func glyph(diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(tint)
                .frame(width: diameter, height: diameter)
            // Wordmark-style notch
            Rectangle()
                .fill(accent)
                .frame(width: diameter * 0.16, height: diameter * 0.48)
                .offset(x: diameter * 0.30, y: 0)
                .mask(
                    Circle()
                        .frame(width: diameter, height: diameter)
                )
        }
    }

    /// The right "I" — a vertical bar inside a filled circle.
    private func glyphBar(diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(tint)
                .frame(width: diameter, height: diameter)
            Capsule()
                .fill(accent)
                .frame(width: diameter * 0.12, height: diameter * 0.5)
        }
    }
}

#Preview("Pill") {
    LogoMark(style: .pill, height: 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.heroBackground)
}

#Preview("Mark") {
    LogoMark(style: .mark, height: 40)
        .padding()
        .background(CouchTheme.primary)
}

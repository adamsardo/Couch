import SwiftUI

/// GO Club-inspired palette: white surfaces, saturated cobalt-blue primary,
/// bright yellow accent, near-black CTAs. Bold, energetic, editorial.
enum CouchTheme {
    static let background = Color(hex: 0xFFFFFF)
    static let surface = Color(hex: 0xFAFAFA)
    static let surfaceMuted = Color(hex: 0xF1F2F4)
    static let divider = Color(hex: 0xE6E6EA)

    /// Saturated GO blue. Used for CTAs, selection states, progress bars,
    /// chart accents, live-transcript highlights.
    static let primary = Color(hex: 0x3A3EFF)
    /// Darker pressed/strong variant used for accented body text where
    /// `primary` would feel too electric.
    static let primaryStrong = Color(hex: 0x2A2EE0)
    /// Soft blue tint for selected pill backgrounds, haloed glyphs, and
    /// muted card fills.
    static let primarySoft = Color(hex: 0xE4E5FF)
    /// Legacy alias kept so existing call sites don't need sweeping edits.
    /// Intentionally distinct from `primary` now — this is the bright
    /// yellow used for hero-screen highlight words.
    static let accent = Color(hex: 0xFFE91C)
    /// Legible variant of `accent` for yellow-on-white body text. Same hue,
    /// dialed-down luminance so it reads on bright backgrounds.
    static let accentOnLight = Color(hex: 0xB59D08)

    static let textPrimary = Color(hex: 0x0A0A0B)
    static let textSecondary = Color(hex: 0x6B6B70)
    static let textMuted = Color(hex: 0x9A9AA2)

    static let success = Color(hex: 0x22C55E)
    static let warning = Color(hex: 0xF59E0B)
    static let danger = Color(hex: 0xEF4444)

    /// Deep navy used as the full-bleed background of the live-call screen.
    static let callSurface = Color(hex: 0x0A0A1A)
    /// Slightly lifted navy for layered elements on the call screen.
    static let callSurfaceMuted = Color(hex: 0x14142A)
    /// Soft-yellow caption colour used on the dark call surface for
    /// "Speaking" hints and agent-turn labels.
    static let callCaption = Color(hex: 0xF6EE8E)

    /// Full-bleed blue hero background. Referenced directly when a screen
    /// needs to paint the entire safe area with the brand colour.
    static let heroBackground = Color(hex: 0x3A3EFF)

    /// Blue-to-blue "accent" gradient used on marketing cards (Today's focus)
    /// and the debrief progress rail where we want a shimmering brand sweep.
    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0x5A5EFF), Color(hex: 0x2A2EE0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Cool-blue ambient gradient used behind the personalising loader.
    static let warmBackgroundGradient = LinearGradient(
        colors: [Color(hex: 0xEEF0FF), Color(hex: 0xFFFFFF)],
        startPoint: .top,
        endPoint: .bottom
    )

    enum Radius {
        static let pill: CGFloat = 999
        static let card: CGFloat = 24
        static let option: CGFloat = 22
        static let control: CGFloat = 28
        static let sheet: CGFloat = 28
        /// Soft container inside a card (review tiles, subtitle pills, notification previews).
        static let bubble: CGFloat = 18
        /// Mid-density panel (inline plan card).
        static let panel: CGFloat = 20
        /// Small chip / app-icon size rectangle.
        static let chip: CGFloat = 10

        /// Derive a concentric inner radius so nested shapes track the outer
        /// one: `inner = outer - padding`, floored at 4pt so corners never
        /// go fully square.
        static func inner(of outer: CGFloat, padding: CGFloat) -> CGFloat {
            max(4, outer - padding)
        }
    }

    enum Spacing {
        /// 4pt. Fine-grain stacking (label-to-control, decorative icon gaps).
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 36
    }

    enum Typography {
        static let display = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title = Font.system(.title, design: .rounded, weight: .bold)
        /// Heavier display weight for GO-style hero headlines where the
        /// headline is the dominant visual.
        static let displayHeavy = Font.system(.largeTitle, design: .rounded, weight: .black)
        /// Heavier title for inline hero copy that needs to punch through a
        /// busy background (blue hero screens).
        static let titleHeavy = Font.system(.title, design: .rounded, weight: .heavy)
        static let sectionTitle = Font.system(.title3, design: .rounded, weight: .semibold)
        static let cardTitle = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .default)
        static let bodyEmphasized = Font.system(.body, design: .default, weight: .semibold)
        static let caption = Font.system(.footnote, design: .rounded)
        /// Tracked-caps eyebrow above a title ("SESSION 1 · FIRST REP").
        /// Pair with `.textCase(.uppercase)` and `.kerning(1.2)`.
        static let eyebrow = Font.system(.caption2, design: .rounded, weight: .semibold)
        static let pill = Font.system(.callout, design: .rounded, weight: .semibold)
        static let pillCTA = Font.system(.title3, design: .rounded, weight: .semibold)
    }
}

extension Color {
    /// Convenience initializer from a 0xRRGGBB literal.
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

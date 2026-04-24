import SwiftUI

/// Brand system for Couch's clinical-skills-simulator direction.
///
/// The app uses these tokens instead of one-off colors so the product reads
/// as warm, safe, and practice-focused across onboarding, reps, debriefs,
/// progress, settings, and launch surfaces.
enum CouchTheme {
    // MARK: - Core palette

    static let lavender = Color(hex: 0xCD88FF)
    static let lavenderSoft = Color(hex: 0xDCC8FF)
    static let deepViolet = Color(hex: 0x5A38FF)
    static let deepVioletAlt = Color(hex: 0x6B4CFF)
    static let blush = Color(hex: 0xF1D6E2)
    static let blushSoft = Color(hex: 0xFFE3EC)
    static let peach = Color(hex: 0xFFC7A6)
    static let peachSoft = Color(hex: 0xFFD4B6)
    static let coral = Color(hex: 0xFF7A7A)
    static let cream = Color(hex: 0xFFF6F1)
    static let creamSoft = Color(hex: 0xFFF7F2)
    static let mist = Color(hex: 0xF1F2F8)
    static let sage = Color(hex: 0xBFE6C9)
    static let ink = Color(hex: 0x111318)
    static let shadow = Color(hex: 0xE9E2F3)
    static let innerShadow = Color(hex: 0xF3EEFB)

    // MARK: - Semantic color aliases

    static let background = cream
    static let surface = Color.white
    static let surfaceMuted = Color(hex: 0xF5F4FA)
    static let divider = ink.opacity(0.08)

    static let primary = deepViolet
    static let primaryStrong = Color(hex: 0x3920C7)
    static let primarySoft = lavenderSoft.opacity(0.62)
    static let accent = peach
    static let accentOnLight = deepVioletAlt

    static let textPrimary = ink
    static let textSecondary = Color(hex: 0x424967)
    static let textMuted = Color(hex: 0x6E748D)

    static let success = Color(hex: 0x40956F)
    static let warning = Color(hex: 0xE79839)
    static let danger = coral

    static let callSurface = Color(hex: 0x111027)
    static let callSurfaceMuted = Color(hex: 0x211C43)
    static let callCaption = peachSoft

    static let heroBackground = LinearGradient(
        colors: [deepViolet, Color(hex: 0x7F67FF), lavenderSoft],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandWash = LinearGradient(
        colors: [creamSoft, lavenderSoft.opacity(0.55), blushSoft.opacity(0.72)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [deepViolet, deepVioletAlt, lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmBackgroundGradient = LinearGradient(
        colors: [creamSoft, blushSoft.opacity(0.8), lavenderSoft.opacity(0.45)],
        startPoint: .top,
        endPoint: .bottom
    )

    enum Radius {
        static let pill: CGFloat = 999
        static let card: CGFloat = 24
        static let option: CGFloat = 22
        static let control: CGFloat = 28
        static let sheet: CGFloat = 30
        static let bubble: CGFloat = 18
        static let panel: CGFloat = 20
        static let chip: CGFloat = 12

        static func inner(of outer: CGFloat, padding: CGFloat) -> CGFloat {
            max(4, outer - padding)
        }
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 36
    }

    enum Typography {
        static let display = Font.system(.largeTitle, design: .rounded, weight: .semibold)
        static let title = Font.system(.title, design: .rounded, weight: .semibold)
        static let displayHeavy = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let titleHeavy = Font.system(.title, design: .rounded, weight: .bold)
        static let sectionTitle = Font.system(.title3, design: .rounded, weight: .semibold)
        static let cardTitle = Font.system(.headline, design: .rounded, weight: .semibold)
        static let body = Font.system(.body, design: .rounded)
        static let bodyEmphasized = Font.system(.body, design: .rounded, weight: .semibold)
        static let caption = Font.system(.footnote, design: .rounded)
        static let eyebrow = Font.system(.caption2, design: .rounded, weight: .bold)
        static let pill = Font.system(.callout, design: .rounded, weight: .semibold)
        static let pillCTA = Font.system(.title3, design: .rounded, weight: .semibold)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

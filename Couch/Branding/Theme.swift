import SwiftUI

/// Flat, high-contrast brand tokens. White surfaces, saturated orange accent, near-black CTAs.
enum CouchTheme {
    static let background = Color(hex: 0xFFFFFF)
    static let surface = Color(hex: 0xFAFAFA)
    static let surfaceMuted = Color(hex: 0xF1F2F4)
    static let divider = Color(hex: 0xE6E6EA)

    static let primary = Color(hex: 0xF97316)
    static let primaryStrong = Color(hex: 0xEA580C)
    static let primarySoft = Color(hex: 0xFFE5D2)
    /// Legacy alias for the primary orange; kept so older cards don't need sweeping edits.
    static let accent = Color(hex: 0xF97316)

    static let textPrimary = Color(hex: 0x0A0A0B)
    static let textSecondary = Color(hex: 0x6B6B70)
    static let textMuted = Color(hex: 0x9A9AA2)

    static let success = Color(hex: 0x22C55E)
    static let warning = Color(hex: 0xF59E0B)
    static let danger = Color(hex: 0xEF4444)

    static let callSurface = Color(hex: 0x0B0B0E)
    static let callSurfaceMuted = Color(hex: 0x1A1A1F)
    static let callCaption = Color(hex: 0xF5B6C6)

    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0xFFB46A), Color(hex: 0xF97316)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmBackgroundGradient = LinearGradient(
        colors: [Color(hex: 0xFFF5EB), Color(hex: 0xFFFFFF)],
        startPoint: .top,
        endPoint: .bottom
    )

    enum Radius {
        static let pill: CGFloat = 999
        static let card: CGFloat = 24
        static let option: CGFloat = 22
        static let control: CGFloat = 28
        static let sheet: CGFloat = 28
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 36
    }

    enum Typography {
        static let display = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title = Font.system(.title, design: .rounded, weight: .bold)
        static let sectionTitle = Font.system(.title3, design: .rounded, weight: .semibold)
        static let cardTitle = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .default)
        static let bodyEmphasized = Font.system(.body, design: .default, weight: .semibold)
        static let caption = Font.system(.footnote, design: .rounded)
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

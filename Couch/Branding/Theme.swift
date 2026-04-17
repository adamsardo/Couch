import SwiftUI

/// Warm, non-clinical brand tokens. Hex values picked for soft contrast and Liquid Glass tinting.
enum CouchTheme {
    static let background = Color(hex: 0xF6F1EC)        // linen
    static let surface = Color(hex: 0xFBF7F2)           // ivory
    static let surfaceMuted = Color(hex: 0xEDE5DA)
    static let primary = Color(hex: 0xB16A4F)           // clay
    static let primaryStrong = Color(hex: 0x8C5239)
    static let accent = Color(hex: 0xD98B59)            // ember
    static let success = Color(hex: 0x6E8C6A)           // sage
    static let warning = Color(hex: 0xC68B3F)
    static let danger = Color(hex: 0xC56B5F)            // soft coral
    static let textPrimary = Color(hex: 0x2A1F2A)       // deep plum
    static let textSecondary = Color(hex: 0x6B5560)
    static let textMuted = Color(hex: 0x8F7C84)
    static let divider = Color(hex: 0xE2D8CD)

    enum Radius {
        static let card: CGFloat = 22
        static let sheet: CGFloat = 28
        static let pill: CGFloat = 999
        static let control: CGFloat = 16
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 36
    }

    enum Typography {
        static let display = Font.system(.largeTitle, design: .rounded, weight: .semibold)
        static let title = Font.system(.title2, design: .rounded, weight: .semibold)
        static let sectionTitle = Font.system(.title3, design: .rounded, weight: .semibold)
        static let cardTitle = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .default)
        static let bodyEmphasized = Font.system(.body, design: .default, weight: .semibold)
        static let caption = Font.system(.footnote, design: .rounded)
        static let pill = Font.system(.callout, design: .rounded, weight: .medium)
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

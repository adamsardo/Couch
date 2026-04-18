import SwiftUI

/// Two-layer elevation system. Small/medium/large map to a consistent depth
/// ladder with a warm neutral shadow that reads better on white/cream
/// surfaces than pure black.
///
/// Usage:
///     content.couchElevation(.md)            // structural card depth
///     content.couchElevation(.lg, tint: .primary) // brand-tinted glow
enum CouchElevation {
    case sm, md, lg

    fileprivate struct Layer {
        let radius: CGFloat
        let y: CGFloat
        let opacity: Double
    }

    fileprivate var layers: (Layer, Layer) {
        switch self {
        case .sm:
            return (
                Layer(radius: 2, y: 1, opacity: 0.05),
                Layer(radius: 8, y: 3, opacity: 0.05)
            )
        case .md:
            return (
                Layer(radius: 3, y: 2, opacity: 0.06),
                Layer(radius: 18, y: 8, opacity: 0.08)
            )
        case .lg:
            return (
                Layer(radius: 4, y: 3, opacity: 0.07),
                Layer(radius: 28, y: 14, opacity: 0.11)
            )
        }
    }
}

extension CouchTheme {
    /// Warm neutral shadow tone. Slightly warmer than `textPrimary` to read
    /// as depth on the app's white + cream surfaces. Not pure black.
    static let shadowWarm = Color(hex: 0x1A120C)
}

private struct CouchElevationModifier: ViewModifier {
    let level: CouchElevation
    let tint: Color?

    func body(content: Content) -> some View {
        let base = tint ?? CouchTheme.shadowWarm
        let (a, b) = level.layers
        content
            .shadow(color: base.opacity(a.opacity), radius: a.radius, x: 0, y: a.y)
            .shadow(color: base.opacity(b.opacity), radius: b.radius, x: 0, y: b.y)
    }
}

extension View {
    /// Apply a two-layer shadow matching the elevation ladder. Pass `tint`
    /// to shift both layers toward a brand color (used for decorative glows).
    func couchElevation(_ level: CouchElevation, tint: Color? = nil) -> some View {
        modifier(CouchElevationModifier(level: level, tint: tint))
    }
}

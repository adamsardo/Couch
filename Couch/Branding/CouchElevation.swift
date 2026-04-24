import SwiftUI

/// Soft two-layer depth ladder tuned for cream, mist, and lavender surfaces.
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
                Layer(radius: 2, y: 1, opacity: 0.06),
                Layer(radius: 8, y: 3, opacity: 0.05)
            )
        case .md:
            return (
                Layer(radius: 4, y: 2, opacity: 0.07),
                Layer(radius: 18, y: 8, opacity: 0.09)
            )
        case .lg:
            return (
                Layer(radius: 6, y: 4, opacity: 0.08),
                Layer(radius: 30, y: 16, opacity: 0.13)
            )
        }
    }
}

extension CouchTheme {
    static let shadowWarm = Color(hex: 0x7E6AAE)
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
    func couchElevation(_ level: CouchElevation, tint: Color? = nil) -> some View {
        modifier(CouchElevationModifier(level: level, tint: tint))
    }
}

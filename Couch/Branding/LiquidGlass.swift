import SwiftUI

/// Thin wrappers over iOS 26 Liquid Glass for floating controls over portraits
/// and dark call surfaces. Use soft cards for normal light content.
enum CouchGlass {
    struct Capsule: ViewModifier {
        var tint: Color? = nil
        var interactive: Bool = false

        func body(content: Content) -> some View {
            content.glassEffect(glassStyle, in: SwiftUI.Capsule())
        }

        private var glassStyle: Glass { CouchGlass.base(interactive: interactive, tint: tint) }
    }

    struct Circle: ViewModifier {
        var tint: Color? = nil
        var interactive: Bool = true

        func body(content: Content) -> some View {
            content.glassEffect(CouchGlass.base(interactive: interactive, tint: tint), in: SwiftUI.Circle())
        }
    }

    struct RoundedRect: ViewModifier {
        var radius: CGFloat
        var tint: Color? = nil

        func body(content: Content) -> some View {
            content.glassEffect(
                CouchGlass.base(interactive: false, tint: tint),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
        }
    }

    fileprivate static func base(interactive: Bool, tint: Color?) -> Glass {
        var glass: Glass = .regular
        if let tint {
            glass = glass.tint(tint)
        }
        if interactive {
            glass = glass.interactive()
        }
        return glass
    }
}

extension View {
    func couchGlassCapsule(tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(CouchGlass.Capsule(tint: tint, interactive: interactive))
    }

    func couchGlassCircle(tint: Color? = nil, interactive: Bool = true) -> some View {
        modifier(CouchGlass.Circle(tint: tint, interactive: interactive))
    }

    func couchGlassRoundedRect(radius: CGFloat, tint: Color? = nil) -> some View {
        modifier(CouchGlass.RoundedRect(radius: radius, tint: tint))
    }
}

private struct ZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var zoomNamespace: Namespace.ID? {
        get { self[ZoomNamespaceKey.self] }
        set { self[ZoomNamespaceKey.self] = newValue }
    }
}

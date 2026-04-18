import SwiftUI

/// Thin, opinionated wrappers over SwiftUI's iOS 26 `.glassEffect` so the
/// whole app adopts Liquid Glass uniformly without repeating config at every
/// call site.
///
/// Use surgically — Liquid Glass is meant for floating controls and overlays,
/// not flat cards on light surfaces. Good homes in Couch: chat bubbles
/// overlaid on portraits, floating back buttons, call-header pills, call
/// control chips, tab-bar accessory.
enum CouchGlass {
    /// Tinted capsule for pills over dark or photographic backgrounds.
    struct Capsule: ViewModifier {
        var tint: Color? = nil
        var interactive: Bool = false

        func body(content: Content) -> some View {
            content.glassEffect(glassStyle, in: SwiftUI.Capsule())
        }

        private var glassStyle: Glass {
            base(interactive: interactive, tint: tint)
        }
    }

    /// Circular glass disc for floating icon buttons.
    struct Circle: ViewModifier {
        var tint: Color? = nil
        var interactive: Bool = true

        func body(content: Content) -> some View {
            content.glassEffect(base(interactive: interactive, tint: tint), in: SwiftUI.Circle())
        }
    }

    /// Rounded-rect glass surface for chat-bubble overlays.
    struct RoundedRect: ViewModifier {
        var radius: CGFloat
        var tint: Color? = nil

        func body(content: Content) -> some View {
            content.glassEffect(
                base(interactive: false, tint: tint),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
        }
    }

    /// Compose the base `Glass` once and let each modifier pick the shape.
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
    /// Apply a tinted glass capsule. Used for call-header pills, small chips.
    func couchGlassCapsule(tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(CouchGlass.Capsule(tint: tint, interactive: interactive))
    }

    /// Apply a glass disc. Used for floating back button over a photo.
    func couchGlassCircle(tint: Color? = nil, interactive: Bool = true) -> some View {
        modifier(CouchGlass.Circle(tint: tint, interactive: interactive))
    }

    /// Apply a glass rounded-rect. Used for chat bubbles overlaid on portraits.
    func couchGlassRoundedRect(radius: CGFloat, tint: Color? = nil) -> some View {
        modifier(CouchGlass.RoundedRect(radius: radius, tint: tint))
    }
}

// MARK: - Shared zoom navigation namespace

/// Environment slot for a `Namespace.ID` so source/destination view pairs
/// across a NavigationStack can share a zoom-transition identifier.
/// Owned by flow containers (e.g. `OnboardingFlow`) and consumed by the
/// source (`matchedTransitionSource`) and destination
/// (`navigationTransition(.zoom(sourceID:in:))`).
private struct ZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var zoomNamespace: Namespace.ID? {
        get { self[ZoomNamespaceKey.self] }
        set { self[ZoomNamespaceKey.self] = newValue }
    }
}

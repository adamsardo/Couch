import SwiftUI

/// Liquid Glass surface modifier with a graceful fallback for pre-iOS 26 simulators/runtime.
///
/// On iOS 26+ we use the system glass effect for cards. On earlier OSes we fall back to
/// `.ultraThinMaterial` plus a soft warm shadow that preserves the brand feel.
struct CouchGlassCardStyle: ViewModifier {
    var radius: CGFloat = CouchTheme.Radius.card
    var tint: Color? = nil

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if #available(iOS 26.0, *) {
            content
                .padding(.vertical, CouchTheme.Spacing.md)
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .glassEffect(.regular.tint(tint ?? .clear), in: shape)
                .overlay(
                    shape.strokeBorder(CouchTheme.divider.opacity(0.5), lineWidth: 0.5)
                )
        } else {
            content
                .padding(.vertical, CouchTheme.Spacing.md)
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .background(.ultraThinMaterial, in: shape)
                .overlay(
                    shape.strokeBorder(CouchTheme.divider.opacity(0.6), lineWidth: 0.5)
                )
                .shadow(color: CouchTheme.primaryStrong.opacity(0.06),
                        radius: 18, x: 0, y: 10)
        }
    }
}

extension View {
    /// Apply the Couch warm-glass card surface.
    func couchGlassCard(radius: CGFloat = CouchTheme.Radius.card, tint: Color? = nil) -> some View {
        modifier(CouchGlassCardStyle(radius: radius, tint: tint))
    }
}

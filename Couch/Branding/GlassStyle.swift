import SwiftUI

/// Flat "soft card" surface: white fill, hairline border, subtle shadow. Named `couchGlassCard`
/// for backward compatibility with existing call sites.
struct CouchGlassCardStyle: ViewModifier {
    var radius: CGFloat = CouchTheme.Radius.card
    var tint: Color? = nil

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(.vertical, CouchTheme.Spacing.md)
            .padding(.horizontal, CouchTheme.Spacing.lg)
            .background(shape.fill(tint ?? CouchTheme.surface))
            .overlay(shape.strokeBorder(CouchTheme.divider, lineWidth: 1))
            .shadow(color: CouchTheme.textPrimary.opacity(0.04), radius: 18, x: 0, y: 6)
    }
}

extension View {
    /// Apply the flat Couch card surface.
    func couchGlassCard(radius: CGFloat = CouchTheme.Radius.card, tint: Color? = nil) -> some View {
        modifier(CouchGlassCardStyle(radius: radius, tint: tint))
    }
}

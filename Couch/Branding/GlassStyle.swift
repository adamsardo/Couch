import SwiftUI

/// Soft card surface used across light Couch screens. The method name is
/// retained for compatibility with existing call sites, but the visual is now
/// a plush cream/mist card rather than old blue GO-style chrome.
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
            .couchElevation(.md)
    }
}

extension View {
    func couchGlassCard(radius: CGFloat = CouchTheme.Radius.card, tint: Color? = nil) -> some View {
        modifier(CouchGlassCardStyle(radius: radius, tint: tint))
    }
}

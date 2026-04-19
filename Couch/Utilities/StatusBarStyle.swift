import SwiftUI

/// Per-screen status-bar style helper. SwiftUI doesn't expose a direct
/// `preferredStatusBarStyle` on iOS 26 without wrapping a UIKit host, but
/// we can set the colour scheme preference for the content hierarchy,
/// which iOS uses when deciding the status-bar style against the
/// backdrop colour.
enum CouchStatusBar {
    case onHero
    case `default`
}

private struct CouchStatusBarModifier: ViewModifier {
    let style: CouchStatusBar

    func body(content: Content) -> some View {
        switch style {
        case .onHero:
            // Dark backdrop → request `.dark` colour scheme for content
            // contrast and let iOS flip the status-bar glyphs to light.
            content.preferredColorScheme(.dark)
        case .default:
            content.preferredColorScheme(.light)
        }
    }
}

extension View {
    /// Apply a status-bar style hint appropriate for the screen's backdrop.
    func couchStatusBar(_ style: CouchStatusBar) -> some View {
        modifier(CouchStatusBarModifier(style: style))
    }
}

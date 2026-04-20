import SwiftUI

/// Adds transparent bottom clearance so floating chrome like tab accessories
/// or pinned CTAs do not obscure the last content on screen.
private struct BottomClearanceInset: View {
    let height: CGFloat

    var body: some View {
        Color.clear
            .frame(height: height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension View {
    func couchBottomClearance(_ height: CGFloat) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            BottomClearanceInset(height: height)
        }
    }
}

import SwiftUI

/// Couch's default button style. Adds a subtle scale + opacity deformation
/// on press (`physics-active-state` / `physics-subtle-deformation`). Keeps
/// the label's own chrome intact — call sites still own the background,
/// padding, and shape.
///
/// Usage:
///     Button { ... } label: { ... }
///         .buttonStyle(.couchPress)
struct CouchPressStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.97
    var pressedOpacity: Double = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(CouchMotion.pressFeedback, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CouchPressStyle {
    /// The default Couch press deformation.
    static var couchPress: CouchPressStyle { CouchPressStyle() }
}

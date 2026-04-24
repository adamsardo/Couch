import SwiftUI

/// Circular back chevron. Uses iOS 26 Liquid Glass over photos and darker
/// surfaces so it reads premium; falls back to an opaque tint pill when
/// the caller opts in with an explicit `background` color.
struct FloatingBackButton: View {
    enum Surface {
        case glass
        case solid(Color)
    }

    var tint: Color = CouchTheme.textPrimary
    /// When non-nil, overrides the default glass surface with a solid fill
    /// (used on light onboarding screens where a glass disc would look
    /// muddled against pure white).
    var background: Color? = nil
    var action: () -> Void

    private var surface: Surface {
        if let background {
            return .solid(background)
        }
        return .glass
    }

    var body: some View {
        Button {
            CouchHaptics.tap()
            action()
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
                .frame(width: 52, height: 52)
                .modifier(BackgroundSurface(surface: surface))
        }
        .contentShape(Circle())
        .buttonStyle(.couchPress)
        .accessibilityLabel("Back")
    }
}

private struct BackgroundSurface: ViewModifier {
    let surface: FloatingBackButton.Surface

    func body(content: Content) -> some View {
        switch surface {
        case .glass:
            content.couchGlassCircle()
        case .solid(let color):
            content.background(
                Circle()
                    .fill(color)
                    .couchElevation(.sm)
            )
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        FloatingBackButton(action: {})
        FloatingBackButton(tint: .white, action: {})
        FloatingBackButton(tint: .white, background: CouchTheme.callSurfaceMuted, action: {})
    }
    .padding()
    .background(CouchTheme.surfaceMuted)
}

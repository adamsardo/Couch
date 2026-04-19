import SwiftUI

/// Reusable shimmer-capable skeleton block. Use as a stand-in for text /
/// card content while data loads; swap in real content once ready.
struct SkeletonPlaceholder: View {
    var cornerRadius: CGFloat = CouchTheme.Radius.bubble
    var height: CGFloat? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(CouchTheme.surfaceMuted)
                .overlay(shimmer(size: proxy.size))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .accessibilityHidden(true)
        }
        .frame(height: height)
    }

    @ViewBuilder
    private func shimmer(size: CGSize) -> some View {
        if reduceMotion {
            Color.clear
        } else {
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0), location: 0),
                    .init(color: .white.opacity(0.5), location: 0.5),
                    .init(color: .white.opacity(0), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: size.width * 0.6, height: size.height)
            .offset(x: -size.width)
            .phaseAnimator([0, 1]) { view, phase in
                view.offset(x: phase == 0 ? -size.width : size.width)
            } animation: { _ in
                .linear(duration: 1.4)
            }
            .blendMode(.plusLighter)
        }
    }
}

extension View {
    /// Show a shimmering skeleton while `isLoading` is true, otherwise
    /// render the wrapped content.
    @ViewBuilder
    func skeleton(_ isLoading: Bool, cornerRadius: CGFloat = CouchTheme.Radius.bubble) -> some View {
        if isLoading {
            SkeletonPlaceholder(cornerRadius: cornerRadius)
        } else {
            self
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SkeletonPlaceholder(cornerRadius: 18, height: 28)
        SkeletonPlaceholder(cornerRadius: 18, height: 20)
            .frame(width: 200)
        SkeletonPlaceholder(cornerRadius: CouchTheme.Radius.card, height: 180)
    }
    .padding()
    .background(CouchTheme.background)
}

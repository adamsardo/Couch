import SwiftUI

/// Concentric dotted rings that pulse on a warm orange gradient.
/// Used by the personalising screen and the post-onboarding "crafting your first insight" moment.
struct OrangeRingLoader: View {
    @State private var pulse: CGFloat = 0.9
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ring(radius: 60, count: 18, size: 6, opacity: 1.0)
            ring(radius: 100, count: 32, size: 6, opacity: 0.75)
            ring(radius: 140, count: 44, size: 6, opacity: 0.55)
            ring(radius: 180, count: 56, size: 6, opacity: 0.35)

            Image(systemName: "heart.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.5), radius: 6)
        }
        .scaleEffect(pulse)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = 1.05
            }
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .accessibilityLabel("Loading")
    }

    @ViewBuilder
    private func ring(radius: CGFloat, count: Int, size: CGFloat, opacity: Double) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: size, height: size)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) / Double(count) * 360))
            }
        }
    }
}

#Preview {
    ZStack {
        CouchTheme.accentGradient.ignoresSafeArea()
        OrangeRingLoader()
    }
}

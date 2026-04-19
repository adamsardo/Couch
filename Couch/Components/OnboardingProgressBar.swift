import SwiftUI

/// Thick pill-progress rail used across onboarding. Optional trailing `Skip`
/// action, and customizable track / fill colours so the same control can
/// render on white form screens (blue fill on gray) or on blue hero
/// screens (white fill on translucent white).
struct OnboardingProgressBar: View {
    var progress: Double
    var onSkip: (() -> Void)? = nil
    var trackColor: Color = CouchTheme.surfaceMuted
    var fillColor: Color = CouchTheme.primary
    var skipColor: Color = CouchTheme.textSecondary

    var body: some View {
        HStack(spacing: CouchTheme.Spacing.md) {
            GeometryReader { proxy in
                let clamped = max(0, min(progress, 1))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackColor)
                    Capsule()
                        .fill(fillColor)
                        .frame(width: proxy.size.width * clamped)
                        .animation(CouchMotion.progressFill, value: clamped)
                }
            }
            .frame(height: 8)

            if let onSkip {
                Button("Skip", action: onSkip)
                    .font(CouchTheme.Typography.bodyEmphasized)
                    .foregroundStyle(skipColor)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        OnboardingProgressBar(progress: 0.1)
        OnboardingProgressBar(progress: 0.45)
        OnboardingProgressBar(progress: 0.8, onSkip: {})
        OnboardingProgressBar(progress: 1.0)
        OnboardingProgressBar(
            progress: 0.6,
            onSkip: {},
            trackColor: .white.opacity(0.25),
            fillColor: .white,
            skipColor: .white
        )
        .padding()
        .background(CouchTheme.heroBackground)
    }
    .padding()
    .background(CouchTheme.background)
}

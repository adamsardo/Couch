import SwiftUI

/// Orange-on-gray progress rail used across onboarding. Optional trailing `Skip` action.
struct OnboardingProgressBar: View {
    var progress: Double
    var onSkip: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: CouchTheme.Spacing.md) {
            GeometryReader { proxy in
                let clamped = max(0, min(progress, 1))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CouchTheme.surfaceMuted)
                    Capsule()
                        .fill(CouchTheme.primary)
                        .frame(width: proxy.size.width * clamped)
                        .animation(CouchMotion.progressFill, value: clamped)
                }
            }
            .frame(height: 8)

            if let onSkip {
                Button("Skip", action: onSkip)
                    .font(CouchTheme.Typography.bodyEmphasized)
                    .foregroundStyle(CouchTheme.textSecondary)
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
    }
    .padding()
    .background(CouchTheme.background)
}

import SwiftUI

struct WelcomeView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Spacer(minLength: 0)
            VStack(spacing: CouchTheme.Spacing.md) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(CouchTheme.primary)
                Text("Practice therapy\nbefore it counts.")
                    .font(CouchTheme.Typography.display)
                    .foregroundStyle(CouchTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Real reps with simulated patients. From your phone, in minutes — not afternoons.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CouchTheme.Spacing.lg)
            }
            Spacer(minLength: 0)
            VStack(spacing: CouchTheme.Spacing.sm) {
                PrimaryButton(title: "Start free practice", systemImage: "arrow.right") {
                    state.advance(to: .safety)
                }
                Text("No account. No paywall before your first session.")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.background)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        WelcomeView(state: OnboardingState())
    }
}

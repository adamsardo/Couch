import SwiftData
import SwiftUI

/// Owns the onboarding NavigationStack. Each step gets a single, clear next action.
struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var state = OnboardingState()

    var body: some View {
        NavigationStack(path: $state.path) {
            WelcomeView(state: state)
                .navigationDestination(for: OnboardingState.Step.self) { step in
                    switch step {
                    case .welcome:
                        WelcomeView(state: state)
                    case .safety:
                        SafetyView(state: state)
                    case .quickProfile:
                        QuickProfileView(state: state)
                    case .friction:
                        FrictionPromptView(state: state)
                    case .scenarioRecommendation:
                        ScenarioRecommendationView(state: state)
                    case .microphone:
                        MicrophonePermissionView(state: state, onComplete: completeOnboarding)
                    }
                }
        }
        .background(CouchTheme.background.ignoresSafeArea())
    }

    private func completeOnboarding() {
        guard let profile = profiles.first else { return }
        state.finish(saveTo: profile, in: modelContext)
    }
}

#Preview("Onboarding") {
    OnboardingFlow()
        .modelContainer(AppModelContainer.previewContainer())
}

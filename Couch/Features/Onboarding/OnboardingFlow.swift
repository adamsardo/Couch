import SwiftData
import SwiftUI

/// Owns the onboarding NavigationStack. Each step gets a single, clear next action
/// and the orange progress bar at the top indicates flow progress.
struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var state = OnboardingState()
    @Namespace private var zoomNamespace

    var body: some View {
        NavigationStack(path: $state.path) {
            NameView(state: state)
                .modifier(OnboardingChrome(state: state, step: .name, canSkip: false, onSkip: {}))
                .navigationDestination(for: OnboardingState.Step.self) { step in
                    screen(for: step)
                        .modifier(OnboardingChrome(
                            state: state,
                            step: step,
                            canSkip: canSkip(step),
                            onSkip: { skip(from: step) }
                        ))
                }
        }
        .tint(CouchTheme.primary)
        .background(CouchTheme.background.ignoresSafeArea())
        .environment(\.zoomNamespace, zoomNamespace)
    }

    @ViewBuilder
    private func screen(for step: OnboardingState.Step) -> some View {
        switch step {
        case .name: NameView(state: state)
        case .privacy: PrivacyConsentView(state: state)
        case .socialProof: SocialProofView(state: state)
        case .stressors: StressorsView(state: state)
        case .goals: GoalsView(state: state)
        case .quickProfile: QuickProfileView(state: state)
        case .scienceChart: ScienceCurveView(state: state)
        case .personalising: PersonalisingView(state: state)
        case .scenarioMatch: ScenarioMatchView(state: state)
        case .scenarioDetail: ScenarioDetailView(state: state)
        case .notifications: NotificationsPermissionView(state: state)
        case .microphone: MicrophonePermissionView(state: state, onComplete: completeOnboarding)
        }
    }

    private func canSkip(_ step: OnboardingState.Step) -> Bool {
        step == .notifications
    }

    private func skip(from step: OnboardingState.Step) {
        switch step {
        case .notifications:
            state.notificationsGranted = false
            state.advance(to: .microphone)
        default:
            break
        }
    }

    private func completeOnboarding() {
        guard let profile = profiles.first else { return }
        state.finish(saveTo: profile, in: modelContext)
    }
}

/// Common chrome: orange progress bar and consistent background. Hidden on the
/// personalising loader because that screen owns its own full-bleed gradient.
private struct OnboardingChrome: ViewModifier {
    let state: OnboardingState
    let step: OnboardingState.Step
    let canSkip: Bool
    let onSkip: () -> Void

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                if showsProgressBar {
                    OnboardingProgressBar(
                        progress: state.progress(for: step),
                        onSkip: canSkip ? onSkip : nil
                    )
                    .padding(.horizontal, CouchTheme.Spacing.lg)
                    .padding(.vertical, 10)
                    .background(CouchTheme.background)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
    }

    private var showsProgressBar: Bool {
        step != .scenarioDetail
    }
}

#Preview("Onboarding") {
    OnboardingFlow()
        .modelContainer(AppModelContainer.previewContainer())
}

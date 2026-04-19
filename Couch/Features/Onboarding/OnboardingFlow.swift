import SwiftData
import SwiftUI

/// Owns the onboarding NavigationStack. Each step gets a single, clear next action
/// and a thick progress rail at the top indicates flow progress. Blue-hero
/// steps swap to a white-on-blue chrome; white-form steps keep the
/// default blue-on-gray rail.
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

/// Blue-hero onboarding steps that want a white-on-blue progress rail.
private let heroSteps: Set<OnboardingState.Step> = [.socialProof, .scienceChart]

/// Common chrome: progress bar and consistent background. Hidden on the
/// personalising loader because that screen owns its own full-bleed gradient,
/// and on the scenario-detail photo hero because the page draws its own
/// floating back button.
private struct OnboardingChrome: ViewModifier {
    let state: OnboardingState
    let step: OnboardingState.Step
    let canSkip: Bool
    let onSkip: () -> Void

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                if showsProgressBar {
                    HStack(spacing: CouchTheme.Spacing.md) {
                        SegmentedProgressBar(
                            current: state.stepIndex(for: step),
                            total: state.visibleStepCount,
                            trackColor: trackColor,
                            fillColor: fillColor
                        )
                        if canSkip {
                            Button("Skip", action: onSkip)
                                .font(CouchTheme.Typography.bodyEmphasized)
                                .foregroundStyle(skipColor)
                        }
                    }
                    .padding(.horizontal, CouchTheme.Spacing.lg)
                    .padding(.vertical, 10)
                    .background(chromeBackground)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
    }

    private var showsProgressBar: Bool {
        step != .scenarioDetail && step != .personalising
    }

    private var isHero: Bool { heroSteps.contains(step) }

    @ViewBuilder
    private var chromeBackground: some View {
        if isHero {
            CouchTheme.heroBackground
        } else {
            CouchTheme.background
        }
    }

    private var trackColor: Color {
        isHero ? .white.opacity(0.25) : CouchTheme.surfaceMuted
    }

    private var fillColor: Color {
        isHero ? .white : CouchTheme.primary
    }

    private var skipColor: Color {
        isHero ? .white.opacity(0.9) : CouchTheme.textSecondary
    }
}

#Preview("Onboarding") {
    OnboardingFlow()
        .modelContainer(AppModelContainer.previewContainer())
}

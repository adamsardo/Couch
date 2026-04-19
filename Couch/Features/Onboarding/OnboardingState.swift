import Foundation
import Observation
import SwiftData

/// State machine driving the onboarding flow. Held by `OnboardingFlow`.
///
/// Each step writes its answers in-memory; only when the flow completes do we
/// persist the resulting fields onto the singleton `UserProfile` and stamp
/// `onboardedAt`, which flips `AppRoot` to the Home experience.
@Observable
@MainActor
final class OnboardingState {
    enum Step: Hashable, CaseIterable {
        case name
        case privacy
        case socialProof
        case stressors
        case goals
        case quickProfile
        case scienceChart
        case personalising
        case scenarioMatch
        case scenarioDetail
        case notifications
        case microphone
    }

    var path: [Step] = []

    var name: String = ""
    var yearLevel: YearLevel?
    var placementWindow: PlacementWindow?
    var stressors: Set<FrictionStressor> = []
    var goals: Set<PracticeGoal> = []
    var consentAccepted: Bool = false
    var notificationsGranted: Bool = false
    var micPermission: MicPermissionStatus = .undetermined
    var sessionMode: SessionMode = .voice
    var didFinish = false

    func advance(to step: Step) {
        path.append(step)
    }

    /// Used by the flow container to render the continuous progress bar.
    func progress(for step: Step) -> Double {
        let ordered = Step.allCases
        guard let index = ordered.firstIndex(of: step) else { return 0 }
        let total = max(ordered.count - 1, 1)
        return Double(index) / Double(total)
    }

    /// Ordered list of steps that show a progress rail. Personalising and
    /// scenario-detail hide the rail; they shouldn't count toward the
    /// segmented progression.
    static let railSteps: [Step] = Step.allCases.filter { step in
        step != .personalising && step != .scenarioDetail
    }

    /// Number of segments the rail should show.
    var visibleStepCount: Int { Self.railSteps.count }

    /// Zero-based index of `step` within the visible rail. Returns -1 for
    /// hidden steps.
    func stepIndex(for step: Step) -> Int {
        Self.railSteps.firstIndex(of: step) ?? -1
    }

    /// Single stressor is still useful elsewhere (e.g. aha-moment copy).
    var primaryStressor: FrictionStressor? {
        stressors.first
    }

    func finish(saveTo profile: UserProfile, in context: ModelContext) {
        profile.name = name.isEmpty ? nil : name
        profile.yearLevel = yearLevel?.rawValue
        profile.placementWindow = placementWindow?.rawValue
        profile.topStressor = primaryStressor?.rawValue
        profile.stressors = stressors.map(\.rawValue)
        profile.goals = goals.map(\.rawValue)
        profile.notificationsEnabled = notificationsGranted
        profile.onboardedAt = .now
        try? context.save()
        didFinish = true
    }
}

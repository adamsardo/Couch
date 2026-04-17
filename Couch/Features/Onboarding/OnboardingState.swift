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
    enum Step: Hashable {
        case welcome
        case safety
        case quickProfile
        case friction
        case scenarioRecommendation
        case microphone
    }

    var path: [Step] = []
    var yearLevel: YearLevel?
    var placementWindow: PlacementWindow?
    var topStressor: FrictionStressor?
    var micPermission: MicPermissionStatus = .undetermined
    var sessionMode: SessionMode = .voice
    var didFinish = false

    func advance(to step: Step) {
        path.append(step)
    }

    func skipQuickProfile() {
        yearLevel = nil
        placementWindow = nil
        advance(to: .friction)
    }

    func finish(saveTo profile: UserProfile, in context: ModelContext) {
        profile.yearLevel = yearLevel?.rawValue
        profile.placementWindow = placementWindow?.rawValue
        profile.topStressor = topStressor?.rawValue
        profile.onboardedAt = .now
        try? context.save()
        didFinish = true
    }
}

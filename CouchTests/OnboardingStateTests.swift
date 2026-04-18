import Foundation
import SwiftData
import Testing
@testable import Couch

@Suite("Onboarding state machine")
@MainActor
struct OnboardingStateTests {
    @Test
    func happyPathTransitions() {
        let state = OnboardingState()
        state.advance(to: .privacy)
        state.advance(to: .stressors)
        state.stressors = [.timePoor]
        state.advance(to: .scenarioMatch)
        state.advance(to: .microphone)
        #expect(state.path.last == .microphone)
        #expect(state.primaryStressor == .timePoor)
    }

    @Test
    func progressAdvancesAcrossSteps() {
        let state = OnboardingState()
        let earlier = state.progress(for: .name)
        let middle = state.progress(for: .personalising)
        let end = state.progress(for: .microphone)
        #expect(earlier < middle)
        #expect(middle < end)
        #expect(end <= 1.0)
        #expect(earlier >= 0.0)
    }

    @Test
    func finishStampsProfileAndFlipsRoot() throws {
        let container = AppModelContainer.previewContainer(seeded: true)
        let context = container.mainContext
        let profile = UserProfile()
        context.insert(profile)
        try context.save()

        let state = OnboardingState()
        state.yearLevel = .fourth
        state.placementWindow = .nextSemester
        state.stressors = [.anxiety]
        state.finish(saveTo: profile, in: context)

        #expect(profile.onboardedAt != nil)
        #expect(profile.yearLevel == YearLevel.fourth.rawValue)
        #expect(profile.topStressor == FrictionStressor.anxiety.rawValue)
        #expect(state.didFinish)
    }
}

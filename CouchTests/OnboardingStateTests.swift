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
        state.advance(to: .safety)
        state.advance(to: .quickProfile)
        state.advance(to: .friction)
        state.topStressor = .timePoor
        state.advance(to: .scenarioRecommendation)
        state.advance(to: .microphone)
        #expect(state.path.last == .microphone)
        #expect(state.topStressor == .timePoor)
    }

    @Test
    func skipQuickProfileClearsAndAdvances() {
        let state = OnboardingState()
        state.yearLevel = .third
        state.placementWindow = .thisSemester
        state.skipQuickProfile()
        #expect(state.yearLevel == nil)
        #expect(state.placementWindow == nil)
        #expect(state.path.last == .friction)
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
        state.topStressor = .anxiety
        state.finish(saveTo: profile, in: context)

        #expect(profile.onboardedAt != nil)
        #expect(profile.yearLevel == YearLevel.fourth.rawValue)
        #expect(profile.topStressor == FrictionStressor.anxiety.rawValue)
        #expect(state.didFinish)
    }
}

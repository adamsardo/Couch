import Foundation
import SwiftUI
import Testing
@testable import Couch

/// Pin the rendering contract of the segmented onboarding bar: segments
/// up to and including `current` are filled, the rest track-tinted.
@Suite("Segmented progress bar")
@MainActor
struct SegmentedProgressBarTests {
    @Test("Zero current fills only the first segment")
    func firstSegment() {
        let lit = litSegments(current: 0, total: 6)
        #expect(lit == [true, false, false, false, false, false])
    }

    @Test("Mid current fills up to and including current")
    func middleSegments() {
        let lit = litSegments(current: 2, total: 6)
        #expect(lit == [true, true, true, false, false, false])
    }

    @Test("Current beyond total clamps to all lit")
    func overflow() {
        let lit = litSegments(current: 99, total: 4)
        #expect(lit == [true, true, true, true])
    }

    @Test("Negative current lights nothing")
    func negative() {
        let lit = litSegments(current: -1, total: 4)
        #expect(lit == [false, false, false, false])
    }

    @Test("OnboardingState reports the right visible step count")
    func visibleStepCount() {
        let state = OnboardingState()
        // personalising + scenarioDetail are hidden.
        let expected = OnboardingState.Step.allCases.count - 2
        #expect(state.visibleStepCount == expected)
    }

    @Test(
        "OnboardingState step index is stable and monotonic across visible steps",
        arguments: [
            (OnboardingState.Step.name, 0),
            (.privacy, 1),
            (.socialProof, 2),
            (.stressors, 3),
            (.goals, 4),
            (.quickProfile, 5),
            (.scienceChart, 6)
        ]
    )
    func indexOrder(step: OnboardingState.Step, expected: Int) {
        let state = OnboardingState()
        #expect(state.stepIndex(for: step) == expected)
    }

    @Test("Hidden steps report -1 so the rail can skip them")
    func hiddenStepsAreNegative() {
        let state = OnboardingState()
        #expect(state.stepIndex(for: .personalising) == -1)
        #expect(state.stepIndex(for: .scenarioDetail) == -1)
    }

    private func litSegments(current: Int, total: Int) -> [Bool] {
        (0..<total).map { index in index <= current }
    }
}

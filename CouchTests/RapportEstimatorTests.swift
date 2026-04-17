import Foundation
import Testing
@testable import Couch

@Suite("Rapport estimator")
struct RapportEstimatorTests {
    @Test
    func startsAtBaseline() {
        #expect(RapportEstimator().estimate(turns: []) == 20)
    }

    struct Sample: Sendable {
        let text: String
        let direction: Direction

        enum Direction: Sendable { case up, down, flat }
    }

    @Test(arguments: [
        Sample(text: "Sounds like work has been wearing you down.", direction: .up),
        Sample(text: "That makes sense given everything.", direction: .up),
        Sample(text: "Have you ever thought about killing yourself?", direction: .down),
        Sample(text: "It sounds like you might have anhedonia.", direction: .down),
        Sample(text: "Tell me about your week.", direction: .flat)
    ])
    func directionMatchesHeuristic(sample: Sample) {
        let baseline = RapportEstimator().estimate(turns: [])
        let after = RapportEstimator().estimate(turns: [
            RapportTurn(role: .user, text: sample.text)
        ])
        switch sample.direction {
        case .up: #expect(after > baseline)
        case .down: #expect(after < baseline)
        case .flat: #expect(after == baseline || after == baseline + 2 || after == baseline - 2)
        }
    }

    @Test
    func clampsToZeroAndHundred() {
        let manyDestructive = Array(repeating: RapportTurn(role: .user, text: "diagnose suicidal anhedonia"), count: 30)
        #expect(RapportEstimator().estimate(turns: manyDestructive) == 0)

        let manySupportive = Array(repeating: RapportTurn(role: .user, text: "sounds like that makes sense tell me more"), count: 30)
        #expect(RapportEstimator().estimate(turns: manySupportive) == 100)
    }
}

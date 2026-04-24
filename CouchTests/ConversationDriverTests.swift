import Foundation
import Testing
@testable import Couch

@Suite("Conversation driver contract")
@MainActor
struct ConversationDriverTests {
    @Test
    func driverEventsAreEquatable() {
        #expect(
            ConversationDriverEvent.phaseChanged(.live)
                == ConversationDriverEvent.phaseChanged(.live)
        )
        #expect(
            ConversationDriverEvent.avatarVideoAvailabilityChanged(true)
                != ConversationDriverEvent.avatarVideoAvailabilityChanged(false)
        )
    }

    @Test
    func turnRolesDistinguishUserAgentAndSystem() {
        let userTurn = ConversationDriverTurn(
            id: UUID(),
            externalID: "x1",
            role: .user,
            text: "hello",
            createdAt: .now
        )
        let agentTurn = ConversationDriverTurn(
            id: UUID(),
            externalID: "x2",
            role: .agent,
            text: "…",
            createdAt: .now
        )
        #expect(userTurn.role == .user)
        #expect(agentTurn.role == .agent)
        #expect(userTurn != agentTurn)
    }

    @Test
    func phasesCoverConnectingLiveErrorAndEnded() {
        let phases: [ConversationDriverPhase] = [
            .idle,
            .connecting,
            .live,
            .ended(reason: "timeout"),
            .error("boom"),
        ]
        #expect(phases.count == 5)
    }
}

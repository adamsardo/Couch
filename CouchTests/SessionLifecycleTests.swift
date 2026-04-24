import Foundation
import SwiftData
import Testing
@testable import Couch

@Suite("Session lifecycle", .serialized)
@MainActor
struct SessionLifecycleTests {
    @Test
    func debriefCompletionUnlocksSessionCompletionAndStreakOnce() throws {
        let container = AppModelContainer.previewContainer(seeded: false)
        let context = container.mainContext
        let scenario = ScenarioCatalog.marcusScenarioModel()
        context.insert(scenario)
        let session = Session(scenario: scenario, status: .awaitingDebrief, mode: .voice, rapportFinal: 64)
        context.insert(session)
        let debrief = Debrief(
            strengths: [
                "You reflected the work pressure.",
                "You waited before shifting topic.",
                "You normalised his hesitation."
            ],
            nextMoves: [
                "Ask one short open question.",
                "Name the feeling first.",
                "Avoid advice until later."
            ],
            microDrillTitle: "Name the feeling",
            microDrillBody: "Reflect the feeling before asking for detail.",
            session: session
        )
        context.insert(debrief)
        try context.save()

        let coordinator = DebriefCoordinator(
            sessionID: session.persistentModelID,
            snapshot: SessionSnapshot(
                scenario: ScenarioSnapshot(
                    id: scenario.id,
                    title: scenario.title,
                    patientName: scenario.patientName,
                    patientAge: scenario.patientAge,
                    summary: scenario.summary
                ),
                turns: [TurnSnapshot(role: .user, text: "Sounds heavy.")],
                rapport: 64,
                elapsed: 120
            ),
            modelContext: context
        )

        coordinator.setConfidence(4)
        #expect(session.status == .awaitingDebrief)
        #expect(debrief.completedAt == nil)

        coordinator.completeDebrief()
        #expect(session.status == .completed)
        #expect(debrief.confidenceAfter == 4)
        #expect(debrief.completedAt != nil)
        #expect(try context.fetch(FetchDescriptor<StreakEvent>()).count == 1)

        coordinator.completeDebrief()
        #expect(try context.fetch(FetchDescriptor<StreakEvent>()).count == 1)
    }

    @Test
    func dataDeletionCanResetLiveKitInstallIdentity() {
        let container = AppModelContainer.previewContainer(seeded: false)
        let context = container.mainContext
        ProfileParticipantIdentityResolver.resetIdentity()
        let first = ProfileParticipantIdentityResolver.resolveIdentity(in: context)
        ProfileParticipantIdentityResolver.resetIdentity()
        let second = ProfileParticipantIdentityResolver.resolveIdentity(in: context)
        #expect(first != second)
        ProfileParticipantIdentityResolver.resetIdentity()
    }
}

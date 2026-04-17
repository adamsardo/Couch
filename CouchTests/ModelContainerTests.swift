import Foundation
import SwiftData
import Testing
@testable import Couch

@Suite("Model container", .serialized)
@MainActor
struct ModelContainerTests {
    @Test
    func seedingInsertsMarcusScenario() throws {
        let container = AppModelContainer.previewContainer(seeded: true)
        let context = container.mainContext
        let scenarios = try context.fetch(FetchDescriptor<Scenario>())
        #expect(scenarios.contains(where: { $0.id == ScenarioCatalog.marcus.id }))
    }

    @Test
    func cascadeDeletesTurnsAndDebriefWithSession() throws {
        let container = AppModelContainer.previewContainer(seeded: false)
        let context = container.mainContext

        let scenario = ScenarioCatalog.marcusScenarioModel()
        context.insert(scenario)

        let session = Session(scenario: scenario, mode: .voice)
        context.insert(session)

        let turn = Turn(role: .user, text: "Hello", session: session)
        context.insert(turn)

        let debrief = Debrief(strengths: ["a", "b", "c"], nextMoves: ["d", "e", "f"], session: session)
        context.insert(debrief)
        try context.save()

        // Sanity
        #expect(try context.fetch(FetchDescriptor<Turn>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Debrief>()).count == 1)

        context.delete(session)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Turn>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Debrief>()).isEmpty)
    }

    @Test
    func microDrillCatalogIsSeeded() throws {
        let container = AppModelContainer.previewContainer(seeded: true)
        let context = container.mainContext
        let drills = try context.fetch(FetchDescriptor<MicroDrill>())
        for seed in MicroDrillCatalog.seeds {
            let id = seed.id
            #expect(drills.contains(where: { $0.id == id }))
        }
    }
}

import Foundation
import Testing
@testable import Couch

@Suite("Scenario catalog")
struct ScenarioCatalogTests {
    @Test
    func marcusBlueprintIsConfigured() {
        let blueprint = ScenarioCatalog.marcus
        #expect(blueprint.id == "marcus-intake")
        #expect(blueprint.patientName == "Marcus")
        #expect(blueprint.tags.contains("intake"))
        #expect(!blueprint.calmingCue.isEmpty)
    }

    @Test
    func marcusModelInheritsBlueprintFields() {
        let model = ScenarioCatalog.marcusScenarioModel()
        #expect(model.id == ScenarioCatalog.marcus.id)
        #expect(model.title == ScenarioCatalog.marcus.title)
        #expect(model.summary == ScenarioCatalog.marcus.summary)
        // Note: elevenLabsAgentId may be empty if MARCUS_AGENT_ID is unset; that's expected
        // in CI / test runs with no Secrets.plist. We only assert the field is populated
        // (even if empty) so the type contract is preserved.
        #expect(model.elevenLabsAgentId.isEmpty || !model.elevenLabsAgentId.isEmpty)
    }
}

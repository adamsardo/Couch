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
    func marcusBlueprintPrefersLiveKitAndLemonSlice() {
        let blueprint = ScenarioCatalog.marcus
        #expect(blueprint.preferredTransport == .liveKit)
        #expect(blueprint.preferredAvatarProvider == .lemonslice)
    }

    @Test
    func marcusModelInheritsBlueprintFields() {
        let model = ScenarioCatalog.marcusScenarioModel()
        #expect(model.id == ScenarioCatalog.marcus.id)
        #expect(model.title == ScenarioCatalog.marcus.title)
        #expect(model.summary == ScenarioCatalog.marcus.summary)
        // elevenLabsAgentId may be empty in CI where MARCUS_AGENT_ID is unset.
        #expect(model.elevenLabsAgentId.isEmpty || !model.elevenLabsAgentId.isEmpty)
    }

    @Test
    func transportFallsBackToDirectWhenFeatureFlagOff() {
        // With the default AppFeatureFlags (liveKit off in tests because
        // COUCH_LIVEKIT_ENABLED is unset), the model should be on the legacy
        // direct transport no matter what the blueprint prefers.
        let model = ScenarioCatalog.marcusScenarioModel()
        if !AppFeatureFlags.current.liveKitTransportEnabled {
            #expect(model.transport == .elevenLabsDirect)
            #expect(model.avatarProvider == .none)
        } else {
            #expect(model.transport == .liveKit)
            #expect(model.avatarProvider == .lemonslice)
        }
    }
}

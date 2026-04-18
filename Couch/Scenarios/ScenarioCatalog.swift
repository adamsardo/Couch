import Foundation

/// Static catalog of launch scenarios. V1 ships with Marcus only, but the structure leaves
/// the door open for additional cases without changing call sites.
enum ScenarioCatalog {
    enum Scenarios {
        static let marcus = ScenarioBlueprint(
            id: "marcus-intake",
            title: "First-session intake",
            patientName: "Marcus",
            patientAge: 28,
            summary: "His partner referred him. He doesn't want to be here. Stay curious, stay calm.",
            openingCue: "Marcus walks in, sits down without a word, and waits for you to start.",
            calmingCue: "Take a breath. Curiosity, not certainty.",
            agentIDInfoPlistKey: "MARCUS_AGENT_ID",
            tags: ["intake", "resistant", "minimisation"],
            preferredTransport: .liveKit,
            preferredAvatarProvider: .lemonslice
        )
    }

    static var marcus: ScenarioBlueprint { Scenarios.marcus }

    /// Build the SwiftData model from the static blueprint. The transport is
    /// chosen from the LiveKit feature flag at seed time so a turnaround is
    /// a single env/plist flip rather than a code change.
    ///
    /// Returning scenarios via this factory (rather than a hard literal)
    /// keeps the seed-first-run and the UI models in sync.
    static func marcusScenarioModel() -> Scenario {
        let blueprint = marcus
        let transport: SessionTransport =
            AppFeatureFlags.current.liveKitTransportEnabled
                ? blueprint.preferredTransport
                : .elevenLabsDirect
        let avatarProvider: ScenarioAvatarProvider =
            transport == .liveKit ? blueprint.preferredAvatarProvider : .none
        return Scenario(
            id: blueprint.id,
            title: blueprint.title,
            patientName: blueprint.patientName,
            patientAge: blueprint.patientAge,
            summary: blueprint.summary,
            openingCue: blueprint.openingCue,
            calmingCue: blueprint.calmingCue,
            elevenLabsAgentId: SecretsProvider.shared.elevenLabsAgentID(forKey: blueprint.agentIDInfoPlistKey),
            transport: transport,
            avatarProvider: avatarProvider,
            tags: blueprint.tags
        )
    }
}

/// Static blueprint for a scenario before it's persisted into SwiftData.
nonisolated struct ScenarioBlueprint: Sendable, Equatable {
    let id: String
    let title: String
    let patientName: String
    let patientAge: Int
    let summary: String
    let openingCue: String
    let calmingCue: String
    let agentIDInfoPlistKey: String
    let tags: [String]
    let preferredTransport: SessionTransport
    let preferredAvatarProvider: ScenarioAvatarProvider
}

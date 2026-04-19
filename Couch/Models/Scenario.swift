import Foundation
import SwiftData

/// Which realtime transport the client should use for a given scenario.
/// Stored as a raw string on the SwiftData model so we can change this at
/// runtime without a schema migration.
///
/// - `liveKit`: connect to LiveKit Cloud via the backend token server. This
///   is the production path for avatar-enabled sessions.
/// - `elevenLabsDirect`: legacy direct-to-ElevenLabs path kept as a fallback
///   during rollout (PRD §6.1).
enum SessionTransport: String, Codable, Sendable {
    case liveKit
    case elevenLabsDirect
}

/// Which avatar provider should be used if the transport is LiveKit.
/// The backend is ultimately authoritative — see `SessionContext.session.avatar`
/// on the token response — but we store a preferred provider so analytics
/// and UI can react without a round-trip.
enum ScenarioAvatarProvider: String, Codable, Sendable {
    case none
    case lemonslice
}

@Model
final class Scenario {
    @Attribute(.unique) var id: String
    var title: String
    var patientName: String
    var patientAge: Int
    var summary: String
    var openingCue: String
    var calmingCue: String
    /// Legacy direct-ElevenLabs agent id. Retained so the elevenLabsDirect
    /// transport keeps working during rollout. New work should configure the
    /// agent server-side via `SessionTransport.liveKit`.
    var elevenLabsAgentId: String
    /// Realtime transport preference for this scenario.
    var transportRaw: String
    /// Preferred avatar provider for this scenario (advisory; the backend
    /// resolves the live identity at dispatch time).
    var avatarProviderRaw: String
    var tags: [String]
    var createdAt: Date

    var transport: SessionTransport {
        get { SessionTransport(rawValue: transportRaw) ?? .elevenLabsDirect }
        set { transportRaw = newValue.rawValue }
    }

    var avatarProvider: ScenarioAvatarProvider {
        get { ScenarioAvatarProvider(rawValue: avatarProviderRaw) ?? .none }
        set { avatarProviderRaw = newValue.rawValue }
    }

    init(
        id: String,
        title: String,
        patientName: String,
        patientAge: Int,
        summary: String,
        openingCue: String,
        calmingCue: String,
        elevenLabsAgentId: String,
        transport: SessionTransport = .elevenLabsDirect,
        avatarProvider: ScenarioAvatarProvider = .none,
        tags: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.patientName = patientName
        self.patientAge = patientAge
        self.summary = summary
        self.openingCue = openingCue
        self.calmingCue = calmingCue
        self.elevenLabsAgentId = elevenLabsAgentId
        self.transportRaw = transport.rawValue
        self.avatarProviderRaw = avatarProvider.rawValue
        self.tags = tags
        self.createdAt = createdAt
    }
}

import Foundation

/// Transport-agnostic live conversation interface used by
/// ``SessionCoordinator``. Each concrete driver owns its own realtime SDK
/// (ElevenLabs today, LiveKit + LemonSlice next) and publishes a common set
/// of observable signals.
///
/// Introducing this seam — rather than growing the existing
/// ElevenLabs-coupled coordinator — is an explicit requirement of the avatar
/// PRD (§6.1 "Session architecture requirement" → session driver abstraction).
@MainActor
protocol ConversationDriver: AnyObject {
    /// Continuous connection / session state stream.
    var events: AsyncStream<ConversationDriverEvent> { get }

    /// Begin the session. Returns once the driver believes the remote side is
    /// either live or has failed. Implementations also push state via
    /// ``events``.
    func start() async throws

    /// Send a text message in-band. The driver is free to no-op if it does
    /// not support text injection (the LiveKit transport uses data channel
    /// messages; the ElevenLabs transport uses its built-in `sendMessage`).
    func sendText(_ text: String) async

    /// Toggle the student's microphone mute state.
    func toggleMute() async

    /// End the session. Idempotent.
    func end() async
}

/// Events published by a ``ConversationDriver``.
///
/// Keeping this a single `enum` lets the coordinator treat both transports
/// uniformly: the same `@Observable` state machine works for the legacy
/// direct-ElevenLabs path and the LiveKit path.
enum ConversationDriverEvent: Sendable, Equatable {
    case phaseChanged(ConversationDriverPhase)
    case agentModeChanged(ConversationDriverAgentMode)
    case muteChanged(Bool)
    /// A new turn (either `user` or `agent`). System turns are inserted
    /// locally by the coordinator (freeze-help, etc.).
    case newTurn(ConversationDriverTurn)
    /// Remote avatar video track first-frame / availability signal. Only the
    /// LiveKit driver emits this; the ElevenLabs driver never will.
    case avatarVideoAvailabilityChanged(Bool)
    /// Non-fatal avatar failure. The session continues audio-only; the view
    /// surfaces a "Video unavailable" hint (PRD §6.5 fallback ladder).
    case avatarStartFailed(String)
}

enum ConversationDriverPhase: Sendable, Equatable {
    case idle
    case connecting
    case live
    case ended(reason: String?)
    case error(String)
}

enum ConversationDriverAgentMode: Sendable, Equatable {
    case idle
    case listening
    case speaking
}

struct ConversationDriverTurn: Sendable, Equatable, Identifiable {
    let id: UUID
    let externalID: String
    let role: TurnRole
    let text: String
    let createdAt: Date
}

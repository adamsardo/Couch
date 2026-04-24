import Foundation
import LiveKit
import OSLog

/// ``ConversationDriver`` that uses a LiveKit room as the realtime transport
/// and (when the backend agent dispatched one) subscribes to a LemonSlice
/// avatar video track (PRD §6.1, §6.5).
///
/// Responsibilities:
///   - connect to the room using a token minted by the Couch backend
///   - publish the student microphone
///   - track the agent participant's connection + speaking state
///   - forward transcription events as turns (via a LiveKit data topic that
///     the agent-side pipeline publishes)
///   - expose the agent's first remote video track for rendering by
///     ``AvatarStageView``
///
/// Session persistence, SwiftData writes, and debrief gating remain the
/// coordinator's responsibility.
@MainActor
final class LiveKitConversationDriver: NSObject, ConversationDriver {
    struct Context {
        let scenarioID: String
        let mode: SessionMode
        let participantName: String
        let participantIdentity: String
    }

    let room: Room
    private let tokenClient: LiveKitTokenClient
    private let context: Context
    private let continuation: AsyncStream<ConversationDriverEvent>.Continuation
    let events: AsyncStream<ConversationDriverEvent>

    /// Latest remote avatar video track, exposed to the stage view.
    private(set) var remoteAvatarTrack: VideoTrack?
    /// True after we observe at least one subscribed remote video track.
    private(set) var hasAvatarFrame: Bool = false
    /// Response block returned by the token server, cached so the UI can
    /// show "Video unavailable" copy when avatars are disabled server-side.
    private(set) var serverAvatarHint: LiveKitTokenResponse.SessionBlock.Avatar?

    /// Transcription segment ids we've already forwarded.
    private var seenTranscriptionIDs: Set<String> = []
    private var hasLoggedFirstTranscript = false
    private var hasLoggedFirstAgentAudio = false

    init(tokenClient: LiveKitTokenClient, context: Context) {
        self.tokenClient = tokenClient
        self.context = context
        self.room = Room()
        var cont: AsyncStream<ConversationDriverEvent>.Continuation!
        self.events = AsyncStream { continuation in cont = continuation }
        self.continuation = cont
        super.init()
        self.room.add(delegate: self)
    }

    deinit {
        continuation.finish()
    }

    func start() async throws {
        continuation.yield(.phaseChanged(.connecting))
        let started = ContinuousClock.now
        do {
            let request = LiveKitTokenRequest(
                scenarioID: context.scenarioID,
                mode: context.mode,
                participantName: context.participantName,
                participantIdentity: context.participantIdentity
            )
            let tokenResponse = try await tokenClient.fetchToken(for: request)
            self.serverAvatarHint = tokenResponse.session.avatar

            let connectStarted = ContinuousClock.now
            try await room.connect(
                url: tokenResponse.serverUrl,
                token: tokenResponse.participantToken
            )
            let connectDuration = connectStarted.duration(to: .now)
            let connectElapsedMs = connectDuration.components.seconds * 1_000
                + connectDuration.components.attoseconds / 1_000_000_000_000_000
            Logger.session.info("LiveKit room connect completed in \(connectElapsedMs, privacy: .public)ms")

            // Publish the student's microphone for voice mode. For text mode
            // we keep the mic disabled so no audio leaves the device.
            try await room.localParticipant.setMicrophone(enabled: context.mode == .voice)

            continuation.yield(.phaseChanged(.live))
            let totalDuration = started.duration(to: .now)
            let totalElapsedMs = totalDuration.components.seconds * 1_000
                + totalDuration.components.attoseconds / 1_000_000_000_000_000
            Logger.session.info("LiveKit session marked live in \(totalElapsedMs, privacy: .public)ms")

            if let hint = serverAvatarHint, !hint.enabled {
                Logger.session.info("LiveKit avatar disabled by backend")
                continuation.yield(.avatarStartFailed("video_disabled_on_server"))
            }
        } catch {
            Logger.session.error("LiveKitConversationDriver.start failed: \(error.localizedDescription, privacy: .public)")
            continuation.yield(.phaseChanged(.error(error.localizedDescription)))
            throw error
        }
    }

    func sendText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            if let payload = trimmed.data(using: .utf8) {
                // LiveKit agents subscribe to the "lk.chat" data topic for
                // in-room text input. Send it as a reliable data packet.
                try await room.localParticipant.publish(
                    data: payload,
                    // LiveKit 2.6 reordered the initializer so `topic:`
                    // comes before `reliable:`.
                    options: DataPublishOptions(topic: "lk.chat", reliable: true)
                )
            }
            // Optimistically echo as a local user turn so the student sees
            // their message immediately.
            continuation.yield(.newTurn(ConversationDriverTurn(
                id: UUID(),
                externalID: "local-text-\(UUID().uuidString)",
                role: .user,
                text: trimmed,
                createdAt: .now
            )))
        } catch {
            Logger.session.error("LiveKit sendText failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func toggleMute() async {
        let isEnabled = room.localParticipant.isMicrophoneEnabled()
        do {
            try await room.localParticipant.setMicrophone(enabled: !isEnabled)
            continuation.yield(.muteChanged(isEnabled))
        } catch {
            Logger.session.error("LiveKit toggleMute failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func end() async {
        await room.disconnect()
        continuation.yield(.phaseChanged(.ended(reason: nil)))
    }

    /// Decode a transcription payload the agent publishes on a known topic.
    /// The payload format mirrors the agents-js transcription frames: a JSON
    /// object with `id`, `text`, `role` (`"user"` or `"agent"`), and `final`.
    private func ingestTranscriptionPayload(_ data: Data) {
        struct TranscriptionFrame: Decodable {
            let id: String
            let text: String
            let role: String?
            let final: Bool?
        }
        guard let frame = try? JSONDecoder().decode(TranscriptionFrame.self, from: data) else {
            return
        }
        guard frame.final ?? true else { return }
        guard !seenTranscriptionIDs.contains(frame.id) else { return }
        seenTranscriptionIDs.insert(frame.id)
        if !hasLoggedFirstTranscript {
            hasLoggedFirstTranscript = true
            Logger.session.info("LiveKit first transcript frame received")
        }
        let role: TurnRole = frame.role == "user" ? .user : .agent
        continuation.yield(.newTurn(ConversationDriverTurn(
            id: UUID(),
            externalID: frame.id,
            role: role,
            text: frame.text,
            createdAt: .now
        )))
    }
}

// MARK: - RoomDelegate

extension LiveKitConversationDriver: RoomDelegate {
    nonisolated func room(
        _ room: Room,
        didUpdateConnectionState state: ConnectionState,
        from oldState: ConnectionState
    ) {
        Task { @MainActor in
            switch state {
            case .disconnected:
                self.continuation.yield(.phaseChanged(.ended(reason: nil)))
            case .connecting, .reconnecting:
                self.continuation.yield(.phaseChanged(.connecting))
            case .connected:
                self.continuation.yield(.phaseChanged(.live))
            @unknown default:
                break
            }
        }
    }

    nonisolated func room(
        _ room: Room,
        participant: RemoteParticipant,
        didSubscribeTrack publication: RemoteTrackPublication
    ) {
        Task { @MainActor in
            guard let track = publication.track else { return }
            switch publication.kind {
            case .video:
                if let videoTrack = track as? VideoTrack {
                    self.remoteAvatarTrack = videoTrack
                    self.hasAvatarFrame = true
                    self.continuation.yield(.avatarVideoAvailabilityChanged(true))
                }
            case .audio:
                if !self.hasLoggedFirstAgentAudio {
                    self.hasLoggedFirstAgentAudio = true
                    Logger.session.info("LiveKit first remote audio subscribed")
                }
                self.continuation.yield(.agentModeChanged(.listening))
            default:
                break
            }
        }
    }

    nonisolated func room(
        _ room: Room,
        participant: RemoteParticipant,
        didUnsubscribeTrack publication: RemoteTrackPublication
    ) {
        Task { @MainActor in
            if publication.kind == .video {
                self.remoteAvatarTrack = nil
                self.hasAvatarFrame = false
                self.continuation.yield(.avatarVideoAvailabilityChanged(false))
            }
        }
    }

    nonisolated func room(
        _ room: Room,
        participant: Participant,
        didUpdateIsSpeaking speaking: Bool
    ) {
        guard participant is RemoteParticipant else { return }
        Task { @MainActor in
            self.continuation.yield(.agentModeChanged(speaking ? .speaking : .listening))
        }
    }

    nonisolated func room(
        _ room: Room,
        participant: RemoteParticipant?,
        didReceiveData data: Data,
        forTopic topic: String
    ) {
        // Agents publish transcription segments under the "lk.transcription"
        // topic. Anything else we ignore — the app does not need generic
        // data-channel semantics in V1.
        guard topic == "lk.transcription" else { return }
        Task { @MainActor in
            self.ingestTranscriptionPayload(data)
        }
    }
}

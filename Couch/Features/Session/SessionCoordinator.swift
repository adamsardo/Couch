import Foundation
import LiveKit
import Observation
import SwiftData
import OSLog

/// Owns one in-flight session. Instead of speaking to a realtime SDK
/// directly, the coordinator now owns a ``ConversationDriver`` (legacy
/// ElevenLabs or LiveKit + LemonSlice) and maps its events into
/// SwiftUI-observable state + SwiftData writes.
///
/// The driver seam is the architectural refactor required by PRD §6.1. It
/// lets us turn LiveKit on/off without rewriting the coordinator each time.
@Observable
@MainActor
final class SessionCoordinator {
    enum Phase: Equatable {
        case intro
        case connecting
        case live
        case ending
        case ended(reason: String?)
        case error(String)
    }

    enum AgentMode: Equatable {
        case idle
        case listening
        case speaking
    }

    var phase: Phase = .intro
    var agentMode: AgentMode = .idle
    var isMuted: Bool = false
    var visibleTurns: [DisplayTurn] = []
    var rapportScore: Int = 20
    var elapsed: TimeInterval = 0

    /// Remote avatar video track when the active driver is LiveKit. `nil`
    /// otherwise or when no track has been subscribed yet.
    var remoteAvatarTrack: VideoTrack? { liveKitDriver?.remoteAvatarTrack }
    /// Whether the client should show a "Video unavailable" hint. True when
    /// we know the backend disabled avatars for this session.
    var shouldShowVideoUnavailableHint: Bool = false
    /// True when the currently active transport can produce live video.
    var avatarCapable: Bool { transport == .liveKit && AppFeatureFlags.current.avatarsEnabled }

    private let scenario: Scenario
    private let scenarioSnapshot: ScenarioSnapshot
    private let mode: SessionMode
    private let transport: SessionTransport
    private let modelContext: ModelContext
    private let store: TranscriptStore
    private let estimator = RapportEstimator()

    private var driver: ConversationDriver?
    private var liveKitDriver: LiveKitConversationDriver? { driver as? LiveKitConversationDriver }
    private var eventTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var sessionID: PersistentIdentifier?
    private var startedAt: Date?

    init(scenario: Scenario, mode: SessionMode, modelContext: ModelContext) {
        self.scenario = scenario
        self.scenarioSnapshot = ScenarioSnapshot(
            id: scenario.id,
            title: scenario.title,
            patientName: scenario.patientName,
            patientAge: scenario.patientAge,
            summary: scenario.summary
        )
        self.mode = mode
        self.modelContext = modelContext
        // Resolve the effective transport now so feature-flag flips only
        // apply to new sessions rather than mid-conversation.
        let flagged = AppFeatureFlags.current.liveKitTransportEnabled
            ? scenario.transport
            : .elevenLabsDirect
        // Fall back to the direct path if the LiveKit backend is missing.
        if flagged == .liveKit && LiveKitTokenClient.resolved() == nil {
            Logger.session.info("LiveKit transport requested but backend is not configured; falling back to elevenLabsDirect.")
            self.transport = .elevenLabsDirect
        } else {
            self.transport = flagged
        }
        self.store = TranscriptStore(modelContainer: modelContext.container)
    }

    deinit {
        eventTask?.cancel()
        timerTask?.cancel()
    }

    var snapshot: SessionSnapshot {
        SessionSnapshot(
            scenario: scenarioSnapshot,
            turns: visibleTurns.map { TurnSnapshot(role: $0.role, text: $0.text) },
            rapport: rapportScore,
            elapsed: elapsed
        )
    }

    var sessionPersistentID: PersistentIdentifier? { sessionID }

    func startConnection() async {
        phase = .connecting
        let session = Session(scenario: scenario, mode: mode)
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            phase = .error("Could not start session: \(error.localizedDescription)")
            return
        }
        sessionID = session.persistentModelID
        startedAt = session.startedAt
        startTimer()

        let driver = makeDriver()
        self.driver = driver
        startObservingEvents(from: driver)

        do {
            try await driver.start()
            CouchHaptics.sessionStart()
        } catch {
            Logger.session.error("driver.start failed: \(error.localizedDescription, privacy: .public)")
            phase = .error(error.localizedDescription)
        }
    }

    func sendText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await driver?.sendText(trimmed)
    }

    func toggleMute() async {
        await driver?.toggleMute()
    }

    func end(reason: String? = nil) async {
        phase = .ending
        timerTask?.cancel()
        timerTask = nil
        await driver?.end()
        if let sessionID {
            try? await store.finishSession(
                sessionID: sessionID,
                endedAt: .now,
                status: .completed,
                rapportFinal: rapportScore
            )
        }
        CouchHaptics.sessionEnd()
        phase = .ended(reason: reason)
        eventTask?.cancel()
        eventTask = nil
    }

    /// Inserts a freeze-help "system" prompt locally without sending it to
    /// the agent. We surface this in the freeze-help sheet — never autoplayed
    /// back to the patient.
    func recordFreezeHelpInteraction(_ prompt: String) {
        let display = DisplayTurn(id: UUID(), externalID: UUID().uuidString, role: .system, text: prompt, createdAt: .now)
        visibleTurns.append(display)
    }

    // MARK: - Driver wiring

    private func makeDriver() -> ConversationDriver {
        switch transport {
        case .liveKit:
            if let tokenClient = LiveKitTokenClient.resolved() {
                let profileIdentity = ProfileParticipantIdentityResolver
                    .resolveIdentity(in: modelContext)
                return LiveKitConversationDriver(
                    tokenClient: tokenClient,
                    context: .init(
                        scenarioID: scenario.id,
                        mode: mode,
                        participantName: "Student",
                        participantIdentity: profileIdentity
                    )
                )
            }
            fallthrough
        case .elevenLabsDirect:
            return ElevenLabsConversationDriver(
                agentId: scenario.elevenLabsAgentId,
                mode: mode
            )
        }
    }

    private func startObservingEvents(from driver: ConversationDriver) {
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            for await event in driver.events {
                guard let self else { return }
                await self.apply(event)
            }
        }
    }

    private func apply(_ event: ConversationDriverEvent) async {
        switch event {
        case .phaseChanged(let driverPhase):
            apply(driverPhase: driverPhase)
        case .agentModeChanged(let mode):
            switch mode {
            case .idle: agentMode = .idle
            case .listening: agentMode = .listening
            case .speaking: agentMode = .speaking
            }
        case .muteChanged(let muted):
            isMuted = muted
        case .newTurn(let turn):
            appendTurn(turn)
        case .avatarVideoAvailabilityChanged(let available):
            shouldShowVideoUnavailableHint = !available && transport == .liveKit
        case .avatarStartFailed:
            shouldShowVideoUnavailableHint = true
        }
    }

    private func apply(driverPhase: ConversationDriverPhase) {
        switch driverPhase {
        case .idle, .connecting:
            phase = .connecting
        case .live:
            phase = .live
        case .ended(let reason):
            phase = .ended(reason: reason)
        case .error(let message):
            phase = .error(message)
        }
    }

    private func appendTurn(_ turn: ConversationDriverTurn) {
        // Dedupe defensively on external id — both drivers make an effort to
        // avoid duplicates, but belt-and-braces protects against transcription
        // reflow edge cases.
        if visibleTurns.contains(where: { $0.externalID == turn.externalID }) {
            return
        }
        let display = DisplayTurn(
            id: turn.id,
            externalID: turn.externalID,
            role: turn.role,
            text: turn.text,
            createdAt: turn.createdAt
        )
        visibleTurns.append(display)
        rapportScore = estimator.estimate(turns: visibleTurns.map {
            RapportTurn(role: $0.role, text: $0.text)
        })
        if let sessionID {
            let snapshot = turn
            Task { [store] in
                _ = try? await store.appendTurn(
                    sessionID: sessionID,
                    role: snapshot.role,
                    text: snapshot.text,
                    createdAt: snapshot.createdAt
                )
            }
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        let started = Date.now
        startedAt = started
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard let self else { return }
                self.elapsed = Date.now.timeIntervalSince(started)
            }
        }
    }
}

struct DisplayTurn: Identifiable, Equatable, Sendable {
    let id: UUID
    let externalID: String
    let role: TurnRole
    let text: String
    let createdAt: Date
}

nonisolated struct SessionSnapshot: Sendable {
    let scenario: ScenarioSnapshot
    let turns: [TurnSnapshot]
    let rapport: Int
    let elapsed: TimeInterval
}

/// Resolves a stable LiveKit participant identity from the single
/// on-device ``UserProfile``, so analytics on the backend can correlate reps
/// without us having to introduce accounts.
enum ProfileParticipantIdentityResolver {
    private static let installIdentityKey = "com.couch.liveKit.participantIdentity"

    /// Stable per-install identity so backend analytics can group reps
    /// without Couch shipping accounts. Cached in UserDefaults on first use.
    static func resolveIdentity(in _: ModelContext) -> String {
        let defaults = UserDefaults.standard
        if let cached = defaults.string(forKey: installIdentityKey), !cached.isEmpty {
            return cached
        }
        let fresh = "student-\(UUID().uuidString.lowercased().prefix(12))"
        defaults.set(fresh, forKey: installIdentityKey)
        return fresh
    }
}

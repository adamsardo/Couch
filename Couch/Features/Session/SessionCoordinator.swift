import Combine
import ElevenLabs
import Foundation
import LiveKit
import Observation
import SwiftData
import OSLog

/// Owns one in-flight session: connects to ElevenLabs, bridges its Combine streams to
/// the SwiftUI layer via @Observable, and persists every turn through `TranscriptStore`.
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

    private let scenario: Scenario
    private let scenarioSnapshot: ScenarioSnapshot
    private let mode: SessionMode
    private let modelContext: ModelContext
    private let store: TranscriptStore
    private let assembler = TranscriptAssembler()
    private let estimator = RapportEstimator()

    private var conversation: Conversation?
    private var cancellables = Set<AnyCancellable>()
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
        self.store = TranscriptStore(modelContainer: modelContext.container)
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
        do {
            let conversation = try await ElevenLabsClient.shared.startConversation(
                agentId: scenario.elevenLabsAgentId,
                textOnly: mode == .text
            )
            self.conversation = conversation
            wireObservers(for: conversation)
            CouchHaptics.sessionStart()
        } catch {
            Logger.session.error("startConversation failed: \(error.localizedDescription, privacy: .public)")
            phase = .error(error.localizedDescription)
        }
    }

    func sendText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let conversation else { return }
        try? await conversation.sendMessage(trimmed)
    }

    func toggleMute() async {
        guard let conversation else { return }
        try? await conversation.toggleMute()
    }

    func end(reason: String? = nil) async {
        phase = .ending
        timerTask?.cancel()
        timerTask = nil
        await conversation?.endConversation()
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
    }

    /// Inserts a freeze-help "system" prompt locally without sending it to the agent.
    /// We surface this in the freeze-help sheet — never autoplayed back to the patient.
    func recordFreezeHelpInteraction(_ prompt: String) {
        let display = DisplayTurn(id: UUID(), externalID: UUID().uuidString, role: .system, text: prompt, createdAt: .now)
        visibleTurns.append(display)
    }

    private func wireObservers(for conversation: Conversation) {
        conversation.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handle(state: state)
            }
            .store(in: &cancellables)

        conversation.$agentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .speaking: self?.agentMode = .speaking
                case .listening, .thinking, .initializing: self?.agentMode = .listening
                default: self?.agentMode = .idle
                }
            }
            .store(in: &cancellables)

        conversation.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.handle(messages: messages)
            }
            .store(in: &cancellables)

        conversation.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] muted in self?.isMuted = muted }
            .store(in: &cancellables)
    }

    private func handle(state: ConversationState) {
        switch state {
        case .idle:
            phase = .connecting
        case .connecting:
            phase = .connecting
        case .active:
            phase = .live
        case .ended(let reason):
            phase = .ended(reason: String(describing: reason))
        case .error(let error):
            phase = .error(String(describing: error))
        }
    }

    private func handle(messages: [Message]) {
        let pending = assembler.newTurns(from: messages)
        guard !pending.isEmpty else { return }
        for turn in pending {
            visibleTurns.append(DisplayTurn(
                id: turn.id,
                externalID: turn.externalID,
                role: turn.role,
                text: turn.text,
                createdAt: turn.createdAt
            ))
        }
        rapportScore = estimator.estimate(turns: visibleTurns.map {
            RapportTurn(role: $0.role, text: $0.text)
        })
        if let sessionID {
            let snapshot = pending
            Task { [store] in
                for turn in snapshot {
                    _ = try? await store.appendTurn(
                        sessionID: sessionID,
                        role: turn.role,
                        text: turn.text,
                        createdAt: turn.createdAt
                    )
                }
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

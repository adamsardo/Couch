import Combine
import ElevenLabs
import Foundation
// Explicit LiveKit import is required under Swift 6's
// `MemberImportVisibility` upcoming feature: the `AgentState` enum that
// `Conversation.$agentState` publishes is defined in LiveKit, and its
// cases (`.speaking`, `.listening`, `.thinking`, `.initializing`) are
// only visible to a consumer that imports the defining module directly.
import LiveKit
import OSLog

/// Legacy ``ConversationDriver`` that speaks directly to the ElevenLabs
/// Conversational AI SDK. Preserved during rollout of the LiveKit transport
/// (PRD §6.1 "keep the current direct ElevenLabs implementation available")
/// so we can fall back without shipping a build.
@MainActor
final class ElevenLabsConversationDriver: ConversationDriver {
    private let agentId: String
    private let textOnly: Bool
    private let assembler: TranscriptAssembler

    private var conversation: Conversation?
    private var cancellables = Set<AnyCancellable>()
    private let continuation: AsyncStream<ConversationDriverEvent>.Continuation
    let events: AsyncStream<ConversationDriverEvent>

    init(agentId: String, mode: SessionMode) {
        self.agentId = agentId
        self.textOnly = mode == .text
        self.assembler = TranscriptAssembler()
        var cont: AsyncStream<ConversationDriverEvent>.Continuation!
        self.events = AsyncStream { continuation in
            cont = continuation
        }
        self.continuation = cont
    }

    deinit {
        continuation.finish()
    }

    func start() async throws {
        continuation.yield(.phaseChanged(.connecting))
        do {
            let conversation = try await ElevenLabsClient.shared.startConversation(
                agentId: agentId,
                textOnly: textOnly
            )
            self.conversation = conversation
            wireObservers(for: conversation)
        } catch {
            Logger.session.error("ElevenLabsConversationDriver.start failed: \(error.localizedDescription, privacy: .public)")
            continuation.yield(.phaseChanged(.error(error.localizedDescription)))
            throw error
        }
    }

    func sendText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let conversation else { return }
        try? await conversation.sendMessage(trimmed)
    }

    func toggleMute() async {
        try? await conversation?.toggleMute()
    }

    func end() async {
        await conversation?.endConversation()
        continuation.yield(.phaseChanged(.ended(reason: nil)))
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
                case .speaking:
                    self?.continuation.yield(.agentModeChanged(.speaking))
                case .listening, .thinking, .initializing:
                    self?.continuation.yield(.agentModeChanged(.listening))
                default:
                    self?.continuation.yield(.agentModeChanged(.idle))
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
            .sink { [weak self] muted in
                self?.continuation.yield(.muteChanged(muted))
            }
            .store(in: &cancellables)
    }

    private func handle(state: ConversationState) {
        switch state {
        case .idle, .connecting:
            continuation.yield(.phaseChanged(.connecting))
        case .active:
            continuation.yield(.phaseChanged(.live))
        case .ended(let reason):
            continuation.yield(.phaseChanged(.ended(reason: String(describing: reason))))
        case .error(let error):
            continuation.yield(.phaseChanged(.error(String(describing: error))))
        }
    }

    private func handle(messages: [Message]) {
        let pending = assembler.newTurns(from: messages)
        for turn in pending {
            continuation.yield(.newTurn(ConversationDriverTurn(
                id: turn.id,
                externalID: turn.externalID,
                role: turn.role,
                text: turn.text,
                createdAt: turn.createdAt
            )))
        }
    }
}

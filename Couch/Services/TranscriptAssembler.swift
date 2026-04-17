import Foundation
import ElevenLabs

/// Converts the rolling array of `Message` values from the ElevenLabs SDK into
/// new turns we should persist. The SDK emits the *full* messages array on every change,
/// so we need to remember which ones we've already seen.
nonisolated final class TranscriptAssembler: @unchecked Sendable {
    private let lock = NSLock()
    private var seen: Set<String> = []

    /// Process a snapshot of messages from the SDK and return only the new turns.
    /// Messages are de-duplicated by their ID so reordering / republish doesn't duplicate writes.
    func newTurns(from snapshot: [Message]) -> [PendingTurn] {
        lock.lock()
        defer { lock.unlock() }
        var fresh: [PendingTurn] = []
        for message in snapshot {
            let key = String(describing: message.id)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            let role: TurnRole = (message.role == .user) ? .user : .agent
            let pending = PendingTurn(
                id: UUID(),
                externalID: key,
                role: role,
                text: message.content,
                createdAt: .now
            )
            fresh.append(pending)
        }
        return fresh
    }

    /// Reset the seen set, e.g. when starting a new session.
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        seen.removeAll()
    }
}

nonisolated struct PendingTurn: Sendable, Equatable {
    let id: UUID
    let externalID: String
    let role: TurnRole
    let text: String
    let createdAt: Date
}

import Foundation
import SwiftData

/// Off-main-actor SwiftData writer for live session turns.
///
/// We use a `@ModelActor` so streaming writes from the ElevenLabs SDK don't block the UI.
/// Cross-isolation handoff uses `PersistentIdentifier` (per the SwiftData / Concurrency rules):
/// no `@Model` instance ever crosses an actor boundary.
@ModelActor
actor TranscriptStore {
    /// Append a turn to a session identified by its `PersistentIdentifier`.
    /// Returns the new turn's identifier so callers can index into the SwiftData store later.
    @discardableResult
    func appendTurn(
        sessionID: PersistentIdentifier,
        role: TurnRole,
        text: String,
        createdAt: Date = .now
    ) throws -> PersistentIdentifier {
        guard let session = self[sessionID, as: Session.self] else {
            throw TranscriptStoreError.sessionNotFound
        }
        let turn = Turn(role: role, text: text, createdAt: createdAt, session: session)
        modelContext.insert(turn)
        try modelContext.save()
        return turn.persistentModelID
    }

    func appendTurns(
        sessionID: PersistentIdentifier,
        turns: [PendingPersistentTurn]
    ) throws {
        guard !turns.isEmpty else { return }
        guard let session = self[sessionID, as: Session.self] else {
            throw TranscriptStoreError.sessionNotFound
        }
        for item in turns {
            let turn = Turn(role: item.role, text: item.text, createdAt: item.createdAt, session: session)
            modelContext.insert(turn)
        }
        try modelContext.save()
    }

    /// Mark a session ended and persist its final state.
    func finishSession(
        sessionID: PersistentIdentifier,
        endedAt: Date = .now,
        status: SessionStatus = .completed,
        rapportFinal: Int
    ) throws {
        guard let session = self[sessionID, as: Session.self] else {
            throw TranscriptStoreError.sessionNotFound
        }
        session.endedAt = endedAt
        session.status = status
        session.rapportFinal = rapportFinal
        try modelContext.save()
    }
}

enum TranscriptStoreError: Error {
    case sessionNotFound
}

nonisolated struct PendingPersistentTurn: Sendable {
    let role: TurnRole
    let text: String
    let createdAt: Date
}

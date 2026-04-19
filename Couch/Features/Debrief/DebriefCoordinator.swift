import Foundation
import Observation
import OSLog
import SwiftData

@Observable
@MainActor
final class DebriefCoordinator {
    enum Phase: Equatable {
        case generating
        case ready
        case error(String)
    }

    var phase: Phase = .generating
    var step: Step = .strengths
    var payload: DebriefPayload?
    var confidenceAfter: Int?

    enum Step: Hashable {
        case strengths
        case nextMoves
        case microDrill
        case confidence
        case completed
    }

    private let sessionID: PersistentIdentifier
    private let snapshot: SessionSnapshot
    private let modelContext: ModelContext
    private let service = DebriefService()

    init(sessionID: PersistentIdentifier, snapshot: SessionSnapshot, modelContext: ModelContext) {
        self.sessionID = sessionID
        self.snapshot = snapshot
        self.modelContext = modelContext
    }

    func generate() async {
        phase = .generating
        do {
            let payload = try await service.generate(scenario: snapshot.scenario, turns: snapshot.turns)
            self.payload = payload
            persist(payload: payload)
            phase = .ready
        } catch {
            Logger.debrief.error("Debrief generation failed: \(error.localizedDescription, privacy: .public)")
            phase = .error(error.localizedDescription)
        }
    }

    func advance() {
        switch step {
        case .strengths: step = .nextMoves
        case .nextMoves: step = .microDrill
        case .microDrill: step = .confidence
        case .confidence: step = .completed
        case .completed: return
        }
        CouchHaptics.stepAdvance()
    }

    func setConfidence(_ value: Int) {
        confidenceAfter = value
        if let session = modelContext.model(for: sessionID) as? Session,
           let debrief = session.debrief {
            debrief.confidenceAfter = value
            debrief.completedAt = .now
            try? modelContext.save()
        }
    }

    private func persist(payload: DebriefPayload) {
        guard let session = modelContext.model(for: sessionID) as? Session else { return }
        let debrief = Debrief(
            strengths: payload.strengths,
            nextMoves: payload.nextMoves,
            microDrillTitle: payload.microDrill.title,
            microDrillBody: payload.microDrill.body,
            notes: payload.notes,
            riskFlags: payload.riskFlags,
            createdAt: .now,
            session: session
        )
        modelContext.insert(debrief)
        let event = StreakEvent(day: .now, sessionID: session.id)
        // Avoid duplicate streak events for the same calendar day.
        let key = StreakEvent.key(for: .now)
        let descriptor = FetchDescriptor<StreakEvent>(predicate: #Predicate { $0.dayKey == key })
        if (try? modelContext.fetch(descriptor).first) == nil {
            modelContext.insert(event)
        }
        try? modelContext.save()
    }
}

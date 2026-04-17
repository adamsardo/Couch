import Foundation
import SwiftData

@Model
final class Debrief {
    @Attribute(.unique) var id: UUID
    var strengths: [String]
    var nextMoves: [String]
    var microDrillTitle: String
    var microDrillBody: String
    var notes: String
    var riskFlags: [String]
    var confidenceBefore: Int?
    var confidenceAfter: Int?
    var createdAt: Date
    var completedAt: Date?
    var session: Session?

    init(
        id: UUID = UUID(),
        strengths: [String] = [],
        nextMoves: [String] = [],
        microDrillTitle: String = "",
        microDrillBody: String = "",
        notes: String = "",
        riskFlags: [String] = [],
        confidenceBefore: Int? = nil,
        confidenceAfter: Int? = nil,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        session: Session? = nil
    ) {
        self.id = id
        self.strengths = strengths
        self.nextMoves = nextMoves
        self.microDrillTitle = microDrillTitle
        self.microDrillBody = microDrillBody
        self.notes = notes
        self.riskFlags = riskFlags
        self.confidenceBefore = confidenceBefore
        self.confidenceAfter = confidenceAfter
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.session = session
    }

    var isComplete: Bool {
        completedAt != nil
    }
}

import Foundation
import SwiftData

enum SessionStatus: String, Codable, Sendable {
    case inProgress
    case awaitingDebrief
    case completed
    case abandoned
}

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var statusRaw: String
    var rapportFinal: Int
    var modeRaw: String

    @Relationship(deleteRule: .nullify) var scenario: Scenario?
    @Relationship(deleteRule: .cascade, inverse: \Turn.session) var turns: [Turn]
    @Relationship(deleteRule: .cascade, inverse: \Debrief.session) var debrief: Debrief?

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var mode: SessionMode {
        get { SessionMode(rawValue: modeRaw) ?? .voice }
        set { modeRaw = newValue.rawValue }
    }

    var duration: TimeInterval {
        (endedAt ?? .now).timeIntervalSince(startedAt)
    }

    init(
        id: UUID = UUID(),
        scenario: Scenario? = nil,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        status: SessionStatus = .inProgress,
        mode: SessionMode = .voice,
        rapportFinal: Int = 0
    ) {
        self.id = id
        self.scenario = scenario
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.statusRaw = status.rawValue
        self.modeRaw = mode.rawValue
        self.rapportFinal = rapportFinal
        self.turns = []
    }
}

enum SessionMode: String, Codable, Sendable {
    case voice
    case text
}

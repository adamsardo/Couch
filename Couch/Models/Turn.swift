import Foundation
import SwiftData

enum TurnRole: String, Codable, Sendable {
    case user
    case agent
    case system
}

@Model
final class Turn {
    @Attribute(.unique) var id: UUID
    var roleRaw: String
    var text: String
    var createdAt: Date
    var session: Session?

    var role: TurnRole {
        get { TurnRole(rawValue: roleRaw) ?? .system }
        set { roleRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), role: TurnRole, text: String, createdAt: Date = .now, session: Session? = nil) {
        self.id = id
        self.roleRaw = role.rawValue
        self.text = text
        self.createdAt = createdAt
        self.session = session
    }
}

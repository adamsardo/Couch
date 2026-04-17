import Foundation
import SwiftData

/// One record per calendar day the user completed at least one session.
/// Used to compute the home streak signal.
@Model
final class StreakEvent {
    @Attribute(.unique) var dayKey: String
    var day: Date
    var sessionID: UUID

    init(day: Date, sessionID: UUID) {
        self.day = day
        self.sessionID = sessionID
        self.dayKey = StreakEvent.key(for: day)
    }

    static func key(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
}

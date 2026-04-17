import Foundation
import Testing
@testable import Couch

@Suite("Streak counting")
struct StreakCounterTests {
    private let calendar = Calendar.current

    @Test
    func emptyEventsIsZero() {
        #expect(StreakCounter.consecutiveDays(events: [], today: .now) == 0)
    }

    @Test
    func consecutiveDaysFromTodayBackwards() {
        let today = calendar.startOfDay(for: .now)
        let events = (0..<3).compactMap { offset -> StreakEvent? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return StreakEvent(day: day, sessionID: UUID())
        }
        let count = StreakCounter.consecutiveDays(events: events, today: today)
        #expect(count == 3)
    }

    @Test
    func breaksOnGap() {
        let today = calendar.startOfDay(for: .now)
        let day1 = today
        let day2 = calendar.date(byAdding: .day, value: -1, to: today)!
        let day4 = calendar.date(byAdding: .day, value: -3, to: today)!
        let events = [
            StreakEvent(day: day1, sessionID: UUID()),
            StreakEvent(day: day2, sessionID: UUID()),
            StreakEvent(day: day4, sessionID: UUID())
        ]
        let count = StreakCounter.consecutiveDays(events: events, today: today)
        #expect(count == 2)
    }
}

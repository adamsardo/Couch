import Foundation
import Testing
@testable import Couch

/// The weekly `CalendarStripView` uses `StreakEvent.key(for:)` to decide
/// which dots are "filled". These tests lock down the keying so the strip
/// can't silently disagree with `StreakCounter` about what day is what.
@Suite("Calendar strip keying")
struct CalendarStripKeyingTests {
    private let calendar = Calendar.current

    @Test("Key for today round-trips through StreakEvent helper")
    func todayKey() {
        let today = Date()
        let key = StreakEvent.key(for: today)
        #expect(key.count == 10)
        #expect(key.contains("-"))
    }

    @Test("Keys differ for consecutive calendar days")
    func adjacentDaysDiffer() throws {
        let day = calendar.startOfDay(for: .now)
        let next = try #require(calendar.date(byAdding: .day, value: 1, to: day))
        #expect(StreakEvent.key(for: day) != StreakEvent.key(for: next))
    }

    @Test("Keys match for different times on the same calendar day")
    func sameDayDifferentTime() throws {
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
        let evening = calendar.date(bySettingHour: 21, minute: 30, second: 0, of: .now)!
        #expect(StreakEvent.key(for: morning) == StreakEvent.key(for: evening))
    }

    @Test("A week of keys produced from a seed date are all distinct")
    func weekKeysUnique() {
        let base = calendar.startOfDay(for: .now)
        let keys = (0..<7).compactMap { offset -> String? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: base) else { return nil }
            return StreakEvent.key(for: date)
        }
        #expect(Set(keys).count == 7)
    }
}

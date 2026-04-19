import SwiftUI

/// Seven-day dot strip showing rep activity across the current week.
/// Each column: a one-letter weekday label + a dot. The dot is filled when
/// a rep was completed that day; today is outlined in the brand colour.
struct CalendarStripView: View {
    /// Set of `StreakEvent.key` strings for days where a rep was completed.
    var activeDayKeys: Set<String>
    var today: Date = .now
    var calendar: Calendar = .current

    private var days: [Day] {
        let weekStart = startOfWeek()
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let key = StreakEvent.key(for: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isFuture = date > today && !isToday
            return Day(
                date: date,
                key: key,
                isToday: isToday,
                isFuture: isFuture,
                isActive: activeDayKeys.contains(key)
            )
        }
    }

    var body: some View {
        HStack(spacing: CouchTheme.Spacing.xs) {
            ForEach(days, id: \.key) { day in
                VStack(spacing: 6) {
                    Text(letter(for: day.date))
                        .font(CouchTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(day.isFuture ? CouchTheme.textMuted.opacity(0.5) : CouchTheme.textMuted)
                    dot(day)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly activity")
    }

    private func dot(_ day: Day) -> some View {
        let diameter: CGFloat = 24
        return ZStack {
            if day.isActive {
                Circle()
                    .fill(CouchTheme.primary)
                    .frame(width: diameter, height: diameter)
                Image(systemName: CouchIcons.checkmark)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .strokeBorder(
                        day.isToday ? CouchTheme.primary : CouchTheme.divider,
                        lineWidth: day.isToday ? 2 : 1
                    )
                    .frame(width: diameter, height: diameter)
                    .background(
                        Circle().fill(day.isFuture ? CouchTheme.surfaceMuted.opacity(0.5) : CouchTheme.surfaceMuted)
                    )
                    .clipShape(Circle())
            }
        }
        .accessibilityLabel(Text(accessibility(for: day)))
    }

    private func startOfWeek() -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        return calendar.date(from: comps) ?? today
    }

    private func letter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "EEEEE" // single-letter weekday
        return formatter.string(from: date).uppercased()
    }

    private func accessibility(for day: Day) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let name = formatter.string(from: day.date)
        if day.isActive { return "\(name), rep completed" }
        if day.isToday { return "\(name), today" }
        return "\(name), no rep" + (day.isFuture ? " yet" : "")
    }

    private struct Day: Hashable {
        let date: Date
        let key: String
        let isToday: Bool
        let isFuture: Bool
        let isActive: Bool
    }
}

#Preview {
    let today = Date()
    let calendar = Calendar.current
    let keys: Set<String> = {
        var set = Set<String>()
        if let d1 = calendar.date(byAdding: .day, value: -1, to: today) {
            set.insert(StreakEvent.key(for: d1))
        }
        if let d2 = calendar.date(byAdding: .day, value: -3, to: today) {
            set.insert(StreakEvent.key(for: d2))
        }
        return set
    }()
    return CalendarStripView(activeDayKeys: keys)
        .padding()
        .background(CouchTheme.background)
}

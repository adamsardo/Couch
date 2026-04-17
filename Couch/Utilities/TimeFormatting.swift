import Foundation

enum TimeFormatting {
    /// Formats a duration as `m:ss`, useful for the session timer.
    static func mmss(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    /// "Today", "Yesterday", or a short relative phrase.
    static func relativeDay(_ date: Date, now: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }
}

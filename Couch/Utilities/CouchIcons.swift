import Foundation

/// Central catalog of SF Symbol names we use throughout the app. Having the
/// names in one place keeps the vocabulary consistent and makes it easy to
/// swap an icon everywhere it's used in a single edit.
enum CouchIcons {
    // Sessions
    static let quickRep = "play.circle.fill"
    static let waveform = "waveform"
    static let micOn = "mic.fill"
    static let micOff = "mic.slash.fill"
    static let endCall = "phone.down.fill"
    static let keyboardOn = "keyboard.fill"
    static let keyboardOff = "keyboard"
    static let lifering = "lifepreserver"
    static let playFill = "play.fill"
    static let recordFill = "record.circle.fill"

    // Navigation / tabs
    static let practice = "bubble.left.and.bubble.right.fill"
    static let progress = "chart.line.uptrend.xyaxis"
    static let home = practice
    static let history = progress
    static let settings = "gearshape"
    static let back = "chevron.left"
    static let close = "xmark"

    // Dashboard
    static let flame = "flame.fill"
    static let target = "target"
    static let sparkles = "sparkles"
    static let heart = "heart.fill"
    static let book = "book.closed.fill"
    static let people = "person.2.fill"
    static let lock = "lock.shield.fill"
    static let shieldCheck = "checkmark.shield.fill"
    static let star = "star.fill"
    static let chart = "chart.line.uptrend.xyaxis"
    static let calendar = "calendar"
    static let clock = "clock"
    static let arrowUpRight = "arrow.up.right"
    static let checkmark = "checkmark"
    static let checkmarkCircle = "checkmark.circle.fill"

    // Debrief
    static let leaf = "leaf.fill"
    static let bookmark = "bookmark.fill"
    static let dialMeter = "gauge.with.dots.needle.bottom.50percent"

    // Privacy / shields
    static let shield = "shield.lefthalf.filled"

    // Feedback / affordances
    static let exclamationTriangle = "exclamationmark.triangle.fill"
    static let arrowRight = "arrow.right"
    static let arrowClockwise = "arrow.clockwise"
    static let bolt = "bolt.fill"
}

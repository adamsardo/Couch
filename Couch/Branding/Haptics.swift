import UIKit

/// Lightweight haptics helper. Centralised so feedback feels consistent
/// across moments.
enum CouchHaptics {
    static func sessionStart() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func sessionEnd() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func tap() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Fires when the live rapport score crosses a new milestone. Rigid,
    /// low-intensity — should feel like a quick "you're getting through"
    /// nudge rather than a reward.
    static func rapportMilestone() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }

    /// Soft tick on each debrief step advance — gives the progression a
    /// physical cadence.
    static func stepAdvance() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
    }

    /// Success feedback when the debrief scorecard lands.
    static func scorecardLand() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

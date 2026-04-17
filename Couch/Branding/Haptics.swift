import UIKit

/// Lightweight haptics helper. Centralised so feedback feels consistent across moments.
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
}

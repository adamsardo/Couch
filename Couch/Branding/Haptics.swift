import UIKit

/// Light haptic vocabulary for practice reps. Haptics should confirm progress
/// without making serious clinical feedback feel gamified.
enum CouchHaptics {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let successGenerator = UINotificationFeedbackGenerator()

    static func tap() {
        lightImpact.impactOccurred(intensity: 0.7)
    }

    static func stepAdvance() {
        lightImpact.impactOccurred(intensity: 0.85)
    }

    static func sessionStart() {
        mediumImpact.impactOccurred(intensity: 0.75)
    }

    static func sessionEnd() {
        mediumImpact.impactOccurred(intensity: 0.65)
    }

    static func rapportMilestone() {
        lightImpact.impactOccurred(intensity: 0.9)
    }

    static func scorecardLand() {
        successGenerator.notificationOccurred(.success)
    }

    static func success() {
        successGenerator.notificationOccurred(.success)
    }
}

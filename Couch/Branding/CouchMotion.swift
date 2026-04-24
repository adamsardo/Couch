import SwiftUI

/// Shared motion tokens. User-initiated transitions stay under 300ms;
/// ambient mascot/progress motion must still be gated by Reduce Motion.
enum CouchMotion {
    static let press: Double = 0.15
    static let small: Double = 0.22
    static let state: Double = 0.28
    static let progress: Double = 0.28
    static let ambient: Double = 1.1

    static let entrance: Animation = .easeOut(duration: small)
    static let exit: Animation = .easeIn(duration: press)
    static let stateChange: Animation = .easeInOut(duration: state)
    static let pressFeedback: Animation = .easeInOut(duration: press)
    static let progressFill: Animation = .easeOut(duration: progress)

    static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

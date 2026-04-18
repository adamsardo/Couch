import SwiftUI

/// Central motion tokens. Keeps durations under the 300ms user-initiated cap
/// and lets the whole app share one rhythm.
///
/// Usage:
///     .animation(CouchMotion.stateChange, value: phase)
///     withAnimation(CouchMotion.pressFeedback) { ... }
///
/// `respecting(_:)` returns `nil` when the Reduce Motion accessibility
/// preference is on, which disables the animation at the call site.
enum CouchMotion {
    /// 150ms. Presses, hovers, toggles.
    static let press: Double = 0.15
    /// 220ms. Small state changes (select, reveal).
    static let small: Double = 0.22
    /// 280ms. Screen-level state changes. Below the 300ms user-initiated cap.
    static let state: Double = 0.28
    /// 280ms. Progress fills — capped under 300ms.
    static let progress: Double = 0.28
    /// 1100ms. Ambient, non-interactive pulses (orb, sparkles). Only used when
    /// Reduce Motion is off; callers must gate on `reduceMotion`.
    static let ambient: Double = 1.1

    /// Entrances arrive fast, settle gently.
    static let entrance: Animation = .easeOut(duration: small)
    /// Exits build momentum before departing.
    static let exit: Animation = .easeIn(duration: press)
    /// Deliberate state transitions.
    static let stateChange: Animation = .easeInOut(duration: state)
    /// Feedback on tap-down/up.
    static let pressFeedback: Animation = .easeInOut(duration: press)
    /// Progress bar fills and determinate steppers.
    static let progressFill: Animation = .easeOut(duration: progress)

    /// Returns `animation` when Reduce Motion is off, `nil` otherwise. The
    /// SwiftUI `.animation(_:value:)` modifier treats `nil` as "no animation".
    static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

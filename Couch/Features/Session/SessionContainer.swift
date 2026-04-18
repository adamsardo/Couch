import SwiftUI

/// Wraps the intro + live flow for a single session presentation. Used by
/// HomeView's "Quick rep" and by the RootTabView bottom accessory.
struct SessionContainer: View {
    let scenario: Scenario
    let mode: SessionMode
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            SessionIntroBridge(scenario: scenario, mode: mode, onClose: onClose)
        }
    }
}

/// Swaps intro for the live conversation view when the user taps Start.
private struct SessionIntroBridge: View {
    let scenario: Scenario
    let mode: SessionMode
    var onClose: () -> Void

    @State private var didStart = false

    var body: some View {
        if didStart {
            ConversationView(scenario: scenario, mode: mode, onClose: onClose)
        } else {
            SessionIntroView(
                scenario: scenario,
                onBack: { onClose() },
                onStart: { didStart = true }
            )
        }
    }
}

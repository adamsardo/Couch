import SwiftUI

/// Animated orb that visualises the agent's listening / speaking / connecting state.
///
/// Uses an implicit `.animation(_:value:)` keyed on `level` (per the SwiftUI correctness checklist),
/// so the pulse only re-runs when the bound value changes.
struct SpeakingOrb: View {
    enum Mode: Equatable {
        case idle
        case connecting
        case listening
        case speaking
    }

    var mode: Mode

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse: CGFloat = 0.85

    private var color: Color {
        switch mode {
        case .idle: return CouchTheme.textMuted
        case .connecting: return CouchTheme.warning
        case .listening: return CouchTheme.accent
        case .speaking: return CouchTheme.primary
        }
    }

    private var scale: CGFloat {
        switch mode {
        case .speaking: return pulse
        case .listening: return 0.95
        default: return 0.9
        }
    }

    private var label: String {
        switch mode {
        case .idle: return "Idle"
        case .connecting: return "Connecting"
        case .listening: return "Listening"
        case .speaking: return "Patient is speaking"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .scaleEffect(scale * 1.3)
            Circle()
                .fill(color.opacity(0.4))
                .scaleEffect(scale * 1.1)
            Circle()
                .fill(color)
                .scaleEffect(scale)
        }
        .frame(width: 96, height: 96)
        .animation(
            CouchMotion.respecting(
                reduceMotion,
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
            ),
            value: pulse
        )
        .animation(CouchMotion.stateChange, value: mode)
        .onAppear {
            guard !reduceMotion else { return }
            pulse = 1.05
        }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    HStack(spacing: 24) {
        SpeakingOrb(mode: .idle)
        SpeakingOrb(mode: .connecting)
        SpeakingOrb(mode: .listening)
        SpeakingOrb(mode: .speaking)
    }
    .padding()
    .background(CouchTheme.background)
}

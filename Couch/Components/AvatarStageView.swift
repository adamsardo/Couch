import LiveKit
import SwiftUI

/// Full-bleed call background. Renders the LiveKit remote avatar video track
/// when one is subscribed, and cross-fades to ``ScenarioPortraitView``
/// whenever no avatar frame is available — the required fallback ladder
/// from PRD §6.5 ("Avatar failure must never equal session failure").
///
/// Two important details:
///
/// 1. The static stage is always mounted. When the track arrives we fade the
///    video on top of it; if the track ever drops, we fade back down to the
///    portrait instead of flashing to black.
/// 2. `Reduce Motion` softens the crossfade so it never competes with the
///    patient's face (PRD §6.8 accessibility).
struct AvatarStageView: View {
    let scenario: Scenario
    let track: VideoTrack?
    let overlays: ScenarioPortraitView.Overlays
    var showVideoUnavailableHint: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ScenarioPortraitView(
                scenario: scenario,
                crop: .full,
                overlays: overlays
            )

            if let track {
                LiveKitAvatarVideoView(track: track)
                    .transition(.opacity.animation(
                        reduceMotion ? .linear(duration: 0.15) : .easeInOut(duration: 0.45)
                    ))
                    .accessibilityLabel("Live avatar video of \(scenario.patientName)")

                // Keep the narrative scrims on top of live video so the glass
                // header + transcript stay readable.
                ScrimOverlay(overlays: overlays)
            }

            if showVideoUnavailableHint {
                VideoUnavailableHint()
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
}

/// Thin SwiftUI wrapper around LiveKit's `SwiftUIVideoView`, pinned to
/// `.scaleAspectFill` so the avatar reads as a full-bleed stage rather than
/// a tiny centered thumbnail inside letterboxing.
private struct LiveKitAvatarVideoView: View {
    let track: VideoTrack

    var body: some View {
        SwiftUIVideoView(track, layoutMode: .fill)
            .layoutPriority(-1)
    }
}

/// Same scrim stack ``ScenarioPortraitView`` applies, replicated on top of
/// the video so the transcript + header keep their contrast.
private struct ScrimOverlay: View {
    let overlays: ScenarioPortraitView.Overlays

    var body: some View {
        ZStack {
            if overlays.contains(.vignette) {
                RadialGradient(
                    colors: [.clear, .black.opacity(0.22)],
                    center: .center,
                    startRadius: 140,
                    endRadius: 420
                )
                .blendMode(.multiply)
                .allowsHitTesting(false)
            }
            if overlays.contains(.topScrim) {
                LinearGradient(
                    colors: [.black.opacity(0.45), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .allowsHitTesting(false)
            }
            if overlays.contains(.bottomScrim) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
        }
    }
}

private struct VideoUnavailableHint: View {
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "video.slash.fill")
                    .font(.caption.weight(.semibold))
                    .accessibilityHidden(true)
                Text("Audio-only session")
                    .font(CouchTheme.Typography.caption)
            }
            .padding(.horizontal, CouchTheme.Spacing.sm)
            .padding(.vertical, 6)
            .foregroundStyle(.white.opacity(0.85))
            .couchGlassCapsule()
            .padding(.bottom, 120) // keep above the control bar
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Video unavailable. Session is running in audio only.")
    }
}

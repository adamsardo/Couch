import SwiftData
import SwiftUI

/// Layered in-call view. Full-bleed portrait sits behind a glass header,
/// overlaid transcript, and a control bar. Reads as a premium video-call
/// experience rather than a stacked form.
struct ConversationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let scenario: Scenario
    let mode: SessionMode
    var onClose: () -> Void

    @State private var coordinator: SessionCoordinator?
    @State private var draft: String = ""
    @State private var showFreeze: Bool = false
    @State private var showTextPanel: Bool = false
    @State private var showDebrief: Bool = false
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            AvatarStageView(
                scenario: scenario,
                track: coordinator?.avatarCapable == true ? coordinator?.remoteAvatarTrack : nil,
                overlays: [.topScrim, .bottomScrim, .vignette],
                showVideoUnavailableHint: coordinator?.shouldShowVideoUnavailableHint ?? false
            )
            .animation(CouchMotion.stateChange, value: coordinator?.remoteAvatarTrack != nil)

            if let coordinator {
                liveBody(coordinator: coordinator)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            let coord = SessionCoordinator(scenario: scenario, mode: mode, modelContext: modelContext)
            coordinator = coord
            await coord.startConnection()
        }
        .fullScreenCover(isPresented: $showDebrief) {
            if let id = coordinator?.sessionPersistentID, let snapshot = coordinator?.snapshot {
                DebriefGateFlow(
                    sessionID: id,
                    snapshot: snapshot
                ) {
                    showDebrief = false
                    onClose()
                }
            }
        }
    }

    @ViewBuilder
    private func liveBody(coordinator: SessionCoordinator) -> some View {
        VStack(spacing: 0) {
            CallHeader(
                patientName: scenario.patientName,
                phase: coordinator.phase,
                elapsed: coordinator.elapsed,
                reduceMotion: reduceMotion
            )
            .padding(.horizontal, CouchTheme.Spacing.md)
            .padding(.top, CouchTheme.Spacing.sm)

            ConnectingHint(phase: coordinator.phase, agentMode: coordinator.agentMode, reduceMotion: reduceMotion)
                .padding(.top, CouchTheme.Spacing.xs)

            Spacer(minLength: 0)

            OverlayTranscript(
                turns: coordinator.visibleTurns,
                scenario: scenario
            )
            .frame(maxHeight: 420)

            CallControlBar(
                isMuted: coordinator.isMuted,
                mode: mode,
                onMuteToggle: { Task { await coordinator.toggleMute() } },
                onFreezeHelp: { showFreeze = true },
                onTextPanel: { showTextPanel = true },
                onEnd: { Task { await endAndPresentDebrief(coordinator: coordinator) } }
            )
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            )
        }
        .sheet(isPresented: $showFreeze) {
            FreezeHelpSheet { prompt in
                draft = prompt
                coordinator.recordFreezeHelpInteraction(prompt)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTextPanel) {
            CallTextPanel(draft: $draft) { text in
                showTextPanel = false
                Task { await coordinator.sendText(text) }
            }
            .presentationDetents([.medium])
        }
        .overlay(alignment: .top) {
            if case .error(let message) = coordinator.phase {
                ErrorBanner(message: message) { onClose() }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity).animation(CouchMotion.entrance),
                        removal: .move(edge: .top).combined(with: .opacity).animation(CouchMotion.exit)
                    ))
            }
        }
        .animation(CouchMotion.stateChange, value: coordinator.phase)
    }

    private func endAndPresentDebrief(coordinator: SessionCoordinator) async {
        await coordinator.end()
        showDebrief = true
    }
}

// MARK: - Header

/// Glass Live pill (pulsing via variable-color symbol effect), centered
/// name + role, glass timer pill with a numeric content transition for
/// tactile rolling digits.
private struct CallHeader: View {
    let patientName: String
    let phase: SessionCoordinator.Phase
    let elapsed: TimeInterval
    let reduceMotion: Bool

    private var isLive: Bool { phase == .live }

    var body: some View {
        HStack(alignment: .center, spacing: CouchTheme.Spacing.sm) {
            LivePill(isLive: isLive, reduceMotion: reduceMotion)

            Spacer(minLength: CouchTheme.Spacing.xs)

            VStack(spacing: 2) {
                Text(patientName)
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(.white)
                Text("AI simulated patient")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(patientName), AI simulated patient")

            Spacer(minLength: CouchTheme.Spacing.xs)

            TimerPill(elapsed: elapsed)
        }
    }
}

private struct LivePill: View {
    let isLive: Bool
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: CouchTheme.Spacing.xs) {
            Image(systemName: "record.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(CouchTheme.danger)
                .symbolEffect(
                    .variableColor.iterative.reversing,
                    options: .repeating,
                    isActive: isLive && !reduceMotion
                )
                .accessibilityHidden(true)
            Text(isLive ? "Live" : "•")
                .font(CouchTheme.Typography.pill)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, CouchTheme.Spacing.sm)
        .padding(.vertical, CouchTheme.Spacing.xs)
        .couchGlassCapsule()
        .accessibilityLabel(isLive ? "Live" : "Connecting")
    }
}

private struct TimerPill: View {
    let elapsed: TimeInterval

    var body: some View {
        Text(TimeFormatting.mmss(elapsed))
            .font(CouchTheme.Typography.pill.monospacedDigit())
            .foregroundStyle(.white)
            .contentTransition(.numericText(countsDown: false))
            .padding(.horizontal, CouchTheme.Spacing.sm)
            .padding(.vertical, CouchTheme.Spacing.xs)
            .couchGlassCapsule()
            .accessibilityLabel("Elapsed \(TimeFormatting.mmss(elapsed))")
    }
}

// MARK: - Connecting hint

/// Subtle one-line hint shown beneath the header depending on phase.
/// Uses a three-dot `phaseAnimator` when connecting, gated by Reduce Motion.
private struct ConnectingHint: View {
    let phase: SessionCoordinator.Phase
    let agentMode: SessionCoordinator.AgentMode
    let reduceMotion: Bool

    var body: some View {
        Group {
            switch phase {
            case .connecting:
                connecting
            case .live:
                if agentMode == .speaking {
                    hint(text: "Speaking", systemImage: "waveform", color: CouchTheme.callCaption)
                } else if agentMode == .listening {
                    hint(text: "Listening", systemImage: "ear", color: .white.opacity(0.75))
                }
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var connecting: some View {
        HStack(spacing: CouchTheme.Spacing.xs) {
            Text("Connecting")
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(.white.opacity(0.8))
            if reduceMotion {
                Text("…")
                    .font(CouchTheme.Typography.bodyEmphasized)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                AnimatedDots()
            }
        }
        .accessibilityLabel("Connecting")
    }

    private func hint(text: String, systemImage: String, color: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(CouchTheme.Typography.pill)
            .foregroundStyle(color)
    }
}

private struct AnimatedDots: View {
    var body: some View {
        HStack(spacing: 3) {
            dot(index: 0)
            dot(index: 1)
            dot(index: 2)
        }
        .accessibilityHidden(true)
    }

    private func dot(index: Int) -> some View {
        Circle()
            .fill(Color.white.opacity(0.7))
            .frame(width: 5, height: 5)
            .phaseAnimator([0.3, 1.0, 0.3]) { view, opacity in
                view.opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: 0.5).delay(Double(index) * 0.15)
            }
    }
}

// MARK: - Overlay transcript

/// Transcript rendered as glass bubbles overlaid on the portrait. Applies
/// a top-edge mask to fade incoming bubbles in from the photo, and a
/// subtle scroll transition so bubbles settle with scale + opacity.
private struct OverlayTranscript: View {
    let turns: [DisplayTurn]
    let scenario: Scenario

    var body: some View {
        TranscriptView(
            turns: turns,
            scenario: scenario,
            appearance: .dark
        )
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.18),
                    .init(color: .black, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Error banner

private struct ErrorBanner: View {
    let message: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(message)
                .font(CouchTheme.Typography.body)
                .foregroundStyle(.white)
            Spacer()
            Button("Close") { onClose() }
                .foregroundStyle(.white)
                .font(CouchTheme.Typography.bodyEmphasized)
        }
        .padding()
        .background(CouchTheme.danger)
    }
}

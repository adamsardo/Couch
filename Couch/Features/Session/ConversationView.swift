import SwiftData
import SwiftUI

/// Dark-mode call UI. Full-bleed patient portrait up top, Live indicator, mm:ss timer,
/// overlaid transcript, and large red circular Mute / End buttons at the bottom.
struct ConversationView: View {
    @Environment(\.modelContext) private var modelContext
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
            CouchTheme.callSurface.ignoresSafeArea()

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
            CallPortrait(
                scenario: scenario,
                phase: coordinator.phase,
                agentMode: coordinator.agentMode,
                elapsed: coordinator.elapsed
            )
            .containerRelativeFrame(.vertical) { length, _ in length * 0.46 }
            .frame(maxWidth: .infinity)

            TranscriptView(
                turns: coordinator.visibleTurns,
                scenario: scenario,
                appearance: .dark
            )
            .frame(maxHeight: .infinity)
            .mask(
                LinearGradient(
                    colors: [.clear, .black, .black, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            CallControlBar(
                isMuted: coordinator.isMuted,
                mode: mode,
                onMuteToggle: { Task { await coordinator.toggleMute() } },
                onFreezeHelp: { showFreeze = true },
                onTextPanel: { showTextPanel = true },
                onEnd: { Task { await endAndPresentDebrief(coordinator: coordinator) } }
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
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: coordinator.phase)
    }

    private func endAndPresentDebrief(coordinator: SessionCoordinator) async {
        await coordinator.end()
        showDebrief = true
    }
}

private struct CallPortrait: View {
    let scenario: Scenario
    let phase: SessionCoordinator.Phase
    let agentMode: SessionCoordinator.AgentMode
    let elapsed: TimeInterval

    var body: some View {
        ZStack {
            portraitBackground

            LinearGradient(
                colors: [.black.opacity(0.4), .clear, .clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                HStack {
                    LivePill(isLive: phase == .live)
                    Spacer()
                    VStack(spacing: 2) {
                        Text(scenario.patientName)
                            .font(CouchTheme.Typography.cardTitle)
                            .foregroundStyle(.white)
                        Text("AI simulated patient")
                            .font(CouchTheme.Typography.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                    TimerPill(elapsed: elapsed)
                }
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .padding(.top, CouchTheme.Spacing.md)

                Spacer()

                if phase == .connecting {
                    Text("Connecting…")
                        .font(CouchTheme.Typography.bodyEmphasized)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.bottom, CouchTheme.Spacing.md)
                } else if agentMode == .speaking {
                    Label("Speaking", systemImage: "waveform")
                        .font(CouchTheme.Typography.pill)
                        .foregroundStyle(CouchTheme.callCaption)
                        .padding(.bottom, CouchTheme.Spacing.md)
                } else if agentMode == .listening {
                    Label("Listening", systemImage: "ear")
                        .font(CouchTheme.Typography.pill)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, CouchTheme.Spacing.md)
                }
            }
        }
    }

    @ViewBuilder
    private var portraitBackground: some View {
        let assetName = "scenario-\(scenario.id)"
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            ZStack {
                LinearGradient(
                    colors: [CouchTheme.callSurfaceMuted, CouchTheme.callSurface],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Text(String(scenario.patientName.prefix(1)))
                    .font(.system(size: 140, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.08))
            }
        }
    }
}

private struct LivePill: View {
    let isLive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(CouchTheme.danger)
                .frame(width: 8, height: 8)
            Text(isLive ? "Live" : "•")
                .font(CouchTheme.Typography.pill)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(CouchTheme.callSurfaceMuted.opacity(0.75)))
    }
}

private struct TimerPill: View {
    let elapsed: TimeInterval

    var body: some View {
        Text(TimeFormatting.mmss(elapsed))
            .font(CouchTheme.Typography.pill.monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(CouchTheme.callSurfaceMuted.opacity(0.75)))
    }
}

private struct ErrorBanner: View {
    let message: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
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

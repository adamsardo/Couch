import SwiftData
import SwiftUI

/// Hosts the live session: top status row, transcript, and control bar.
/// Presents the debrief gate as a non-dismissable fullScreenCover when the user ends.
struct ConversationView: View {
    @Environment(\.modelContext) private var modelContext
    let scenario: Scenario
    let mode: SessionMode
    var onClose: () -> Void

    @State private var coordinator: SessionCoordinator?
    @State private var draft: String = ""
    @State private var showFreeze: Bool = false
    @State private var showDebrief: Bool = false
    @State private var hasStarted = false

    var body: some View {
        Group {
            if let coordinator {
                liveBody(coordinator: coordinator)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CouchTheme.background)
            }
        }
        .background(CouchTheme.background.ignoresSafeArea())
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
            sessionHeader(coordinator: coordinator)
            TranscriptView(turns: coordinator.visibleTurns, scenario: scenario)
                .frame(maxHeight: .infinity)
            SessionControlBar(
                draft: $draft,
                mode: mode,
                isMuted: coordinator.isMuted,
                onSend: { text in Task { await coordinator.sendText(text) } },
                onMuteToggle: { Task { await coordinator.toggleMute() } },
                onFreezeHelp: { showFreeze = true },
                onEnd: { Task { await endAndPresentDebrief(coordinator: coordinator) } }
            )
        }
        .sheet(isPresented: $showFreeze) {
            FreezeHelpSheet { prompt in
                draft = prompt
                coordinator.recordFreezeHelpInteraction(prompt)
            }
        }
        .overlay(alignment: .top) {
            if case .error(let message) = coordinator.phase {
                ErrorBanner(message: message) { onClose() }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: coordinator.phase)
    }

    private func sessionHeader(coordinator: SessionCoordinator) -> some View {
        HStack(spacing: CouchTheme.Spacing.md) {
            SpeakingOrb(mode: orbMode(for: coordinator))
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario.patientName)
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text(headerSubtitle(coordinator: coordinator))
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
            Spacer()
            Text(TimeFormatting.mmss(coordinator.elapsed))
                .font(CouchTheme.Typography.bodyEmphasized.monospacedDigit())
                .foregroundStyle(CouchTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(CouchTheme.surface))
                .overlay(Capsule().strokeBorder(CouchTheme.divider, lineWidth: 1))
        }
        .padding(.horizontal, CouchTheme.Spacing.lg)
        .padding(.vertical, CouchTheme.Spacing.md)
    }

    private func orbMode(for coordinator: SessionCoordinator) -> SpeakingOrb.Mode {
        switch coordinator.phase {
        case .intro: return .idle
        case .connecting: return .connecting
        case .live, .ending:
            return coordinator.agentMode == .speaking ? .speaking : .listening
        case .ended, .error: return .idle
        }
    }

    private func headerSubtitle(coordinator: SessionCoordinator) -> String {
        switch coordinator.phase {
        case .intro: return "Getting ready…"
        case .connecting: return "Connecting…"
        case .live:
            switch coordinator.agentMode {
            case .speaking: return "Speaking"
            case .listening: return "Listening"
            case .idle: return "Live"
            }
        case .ending: return "Wrapping up…"
        case .ended: return "Session ended"
        case .error(let m): return m
        }
    }

    private func endAndPresentDebrief(coordinator: SessionCoordinator) async {
        await coordinator.end()
        showDebrief = true
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

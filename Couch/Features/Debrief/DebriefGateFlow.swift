import SwiftData
import SwiftUI

/// Non-dismissable post-session debrief. Sequenced so the user must view all stages
/// before the completion gate exposes "start another rep" / "back to home".
struct DebriefGateFlow: View {
    let sessionID: PersistentIdentifier
    let snapshot: SessionSnapshot
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var coordinator: DebriefCoordinator?

    var body: some View {
        Group {
            if let coordinator {
                content(coordinator: coordinator)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CouchTheme.background)
            }
        }
        .background(CouchTheme.background.ignoresSafeArea())
        .interactiveDismissDisabled(true)
        .task {
            guard coordinator == nil else { return }
            let coord = DebriefCoordinator(sessionID: sessionID, snapshot: snapshot, modelContext: modelContext)
            coordinator = coord
            await coord.generate()
            CouchHaptics.success()
        }
    }

    @ViewBuilder
    private func content(coordinator: DebriefCoordinator) -> some View {
        switch coordinator.phase {
        case .generating:
            DebriefGenerationView()
        case .error(let message):
            DebriefErrorView(message: message,
                              retry: { Task { await coordinator.generate() } },
                              dismiss: onComplete)
        case .ready:
            if let payload = coordinator.payload {
                DebriefStepsView(
                    coordinator: coordinator,
                    payload: payload,
                    snapshot: snapshot,
                    onComplete: onComplete
                )
            }
        }
    }
}

private struct DebriefStepsView: View {
    @Bindable var coordinator: DebriefCoordinator
    let payload: DebriefPayload
    let snapshot: SessionSnapshot
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DebriefHeader(step: coordinator.step)

            ScrollView {
                VStack(spacing: CouchTheme.Spacing.lg) {
                    stepContent
                        .transition(.asymmetric(
                            insertion: .opacity
                                .combined(with: .offset(x: 20))
                                .animation(.easeOut(duration: CouchMotion.state)),
                            removal: .opacity
                                .combined(with: .offset(x: -20))
                                .animation(.easeIn(duration: CouchMotion.press))
                        ))
                        .id(coordinator.step)
                }
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .padding(.top, CouchTheme.Spacing.md)
                .padding(.bottom, CouchTheme.Spacing.xl)
                .animation(CouchMotion.stateChange, value: coordinator.step)
            }

            footerControls
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch coordinator.step {
        case .strengths:
            StrengthsCard(strengths: payload.strengths)
        case .nextMoves:
            NextMovesCard(items: payload.nextMoves)
        case .microDrill:
            MicroDrillCard(payload: payload.microDrill)
        case .confidence:
            ConfidenceCheckpointView(coordinator: coordinator)
        case .completed:
            CompletionView(
                snapshot: snapshot,
                payload: payload,
                confidenceAfter: coordinator.confidenceAfter,
                onComplete: onComplete
            )
        }
    }

    @ViewBuilder
    private var footerControls: some View {
        switch coordinator.step {
        case .strengths, .nextMoves, .microDrill:
            VStack {
                PrimaryButton(title: ctaLabel, systemImage: "arrow.right") {
                    coordinator.advance()
                }
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
            .padding(.bottom, CouchTheme.Spacing.lg)
        case .confidence, .completed:
            EmptyView()
        }
    }

    private var ctaLabel: String {
        switch coordinator.step {
        case .strengths: return "Now what to sharpen"
        case .nextMoves: return "Pick a focus"
        case .microDrill: return "How do you feel?"
        default: return "Continue"
        }
    }
}

private struct DebriefHeader: View {
    let step: DebriefCoordinator.Step

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.xs) {
            Text(headline)
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
            Text(subtitle)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.textSecondary)
                .multilineTextAlignment(.center)
            ProgressBar(step: step)
                .padding(.top, CouchTheme.Spacing.xs + 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, CouchTheme.Spacing.lg)
        .padding(.top, CouchTheme.Spacing.lg)
    }

    private var headline: String {
        switch step {
        case .strengths: return "What you did well"
        case .nextMoves: return "What to sharpen next"
        case .microDrill: return "Your micro-drill"
        case .confidence: return "How ready do you feel?"
        case .completed: return "Nice rep"
        }
    }

    private var subtitle: String {
        switch step {
        case .strengths: return "Three things that landed in the room."
        case .nextMoves: return "Specific moves to try next time."
        case .microDrill: return "One focused practice prompt for your next session."
        case .confidence: return "Quick gut-check. We use this to track momentum."
        case .completed: return "You're done. The reps compound from here."
        }
    }
}

private struct ProgressBar: View {
    let step: DebriefCoordinator.Step

    private var progress: Double {
        switch step {
        case .strengths: return 0.25
        case .nextMoves: return 0.5
        case .microDrill: return 0.75
        case .confidence: return 0.9
        case .completed: return 1.0
        }
    }

    private var stepIndex: Int {
        switch step {
        case .strengths: return 1
        case .nextMoves: return 2
        case .microDrill: return 3
        case .confidence: return 4
        case .completed: return 5
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(CouchTheme.divider).frame(height: 6)
                Capsule()
                    .fill(LinearGradient(
                        colors: [CouchTheme.primary, CouchTheme.accent],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress, height: 6)
                    .animation(CouchMotion.progressFill, value: progress)
            }
        }
        .frame(height: 6)
        .frame(maxWidth: 220)
        .accessibilityValue("Step \(stepIndex) of 5")
    }
}

// MARK: - Completion celebration

private struct CompletionView: View {
    let snapshot: SessionSnapshot
    let payload: DebriefPayload
    let confidenceAfter: Int?
    var onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            hero

            Text("Reps compound from here.")
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("You can do another one now or save this one as today's win.")
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textSecondary)
                .multilineTextAlignment(.center)

            metricStrip

            VStack(spacing: CouchTheme.Spacing.sm) {
                PrimaryButton(title: "Do another rep", systemImage: "arrow.clockwise") {
                    onComplete()
                }
                SecondaryButton(title: "Back to home") {
                    onComplete()
                }
            }
            .padding(.top, CouchTheme.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .couchGlassCard()
        .task {
            // Trigger bounce on arrival.
            try? await Task.sleep(for: .milliseconds(120))
            appeared = true
            CouchHaptics.scorecardLand()
        }
    }

    private var hero: some View {
        ZStack {
            Circle()
                .fill(CouchTheme.primary.opacity(0.12))
                .frame(width: 110, height: 110)
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(CouchTheme.primary)
                .symbolEffect(.bounce, value: appeared)
                .symbolEffect(
                    .pulse.byLayer,
                    options: .repeating.speed(0.4),
                    isActive: !reduceMotion
                )
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Session complete")
    }

    private var metricStrip: some View {
        VStack(spacing: CouchTheme.Spacing.sm) {
            HStack(spacing: CouchTheme.Spacing.sm) {
                StatTile(value: TimeFormatting.mmss(snapshot.elapsed), caption: "Elapsed")
                StatTile(value: "\(snapshot.turns.count)", caption: "Turns")
                StatTile(value: "\(snapshot.rapport)", caption: "Rapport")
            }
            HStack(spacing: CouchTheme.Spacing.sm) {
                StatTile(value: "\(payload.strengths.count)", caption: "Strengths")
                StatTile(value: "\(payload.nextMoves.count)", caption: "Next moves")
                StatTile(
                    value: confidenceAfterText,
                    caption: "Confidence"
                )
            }
        }
    }

    private var confidenceAfterText: String {
        if let after = confidenceAfter {
            return "\(after)/5"
        }
        return "–"
    }
}

private struct DebriefErrorView: View {
    let message: String
    var retry: () -> Void
    var dismiss: () -> Void

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(CouchTheme.warning)
                .accessibilityHidden(true)
            Text("Couldn't generate your debrief")
                .font(CouchTheme.Typography.title)
            Text(message)
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CouchTheme.Spacing.md)
            VStack(spacing: CouchTheme.Spacing.sm) {
                PrimaryButton(title: "Try again", systemImage: "arrow.clockwise", action: retry)
                SecondaryButton(title: "Back to home", action: dismiss)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

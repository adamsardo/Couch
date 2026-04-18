import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]
    @Query(sort: \Session.startedAt, order: .reverse) private var sessions: [Session]
    @Query(sort: \StreakEvent.day, order: .reverse) private var streakEvents: [StreakEvent]

    @State private var presentedScenario: Scenario?
    @State private var presentedSessionMode: SessionMode = .voice
    @State private var showCheckpoint = false

    private let weeklyRepsGoal = 3

    private var primaryScenario: Scenario? {
        scenarios.first(where: { $0.id == ScenarioCatalog.marcus.id }) ?? scenarios.first
    }

    private var lastCompletedSession: Session? {
        sessions.first(where: { $0.status == .completed && $0.debrief != nil })
    }

    private var lastDebrief: Debrief? { lastCompletedSession?.debrief }

    private var completedThisWeek: Int {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -7, to: .now) else { return 0 }
        return sessions.filter { $0.status == .completed && $0.startedAt >= start }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: CouchTheme.Spacing.lg) {
                if let scenario = primaryScenario {
                    PatientHeroCard(
                        scenario: scenario,
                        remaining: max(0, weeklyRepsGoal - completedThisWeek),
                        onQuickRep: { startSession(with: scenario, mode: presentedSessionMode) }
                    )
                    .homeCardScrollTransition()
                }

                StateOfMindSection(
                    repsDone: completedThisWeek,
                    repsGoal: weeklyRepsGoal,
                    onCheckup: { showCheckpoint = true }
                )
                .homeCardScrollTransition()

                if profile.ahaShown == false, lastDebrief != nil, let stressor = profile.topStressor.flatMap(FrictionStressor.init) {
                    AhaMomentCard(stressor: stressor) {
                        profile.ahaShown = true
                        try? modelContext.save()
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96)
                            .combined(with: .opacity)
                            .animation(.easeOut(duration: CouchMotion.small)),
                        removal: .opacity.animation(.easeIn(duration: CouchMotion.press))
                    ))
                }

                TodaysFocusCard(debrief: lastDebrief)
                    .homeCardScrollTransition()

                if let drill = lastDebrief {
                    RecentHighlightsCard(strengths: drill.strengths)
                        .homeCardScrollTransition()
                }
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
            .padding(.top, CouchTheme.Spacing.md)
            .padding(.bottom, CouchTheme.Spacing.xl)
            .animation(CouchMotion.stateChange, value: profile.ahaShown)
        }
        .background(CouchTheme.background.ignoresSafeArea())
        .fullScreenCover(item: $presentedScenario) { scenario in
            SessionContainer(
                scenario: scenario,
                mode: presentedSessionMode,
                onClose: { presentedScenario = nil }
            )
        }
        .sheet(isPresented: $showCheckpoint) {
            ConfidenceCheckupSheet { showCheckpoint = false }
                .presentationDetents([.medium])
        }
    }

    private func startSession(with scenario: Scenario, mode: SessionMode) {
        presentedSessionMode = mode
        presentedScenario = scenario
    }
}

// MARK: - Hero card

private struct PatientHeroCard: View {
    let scenario: Scenario
    let remaining: Int
    var onQuickRep: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: CouchTheme.Spacing.md) {
            avatarRing

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.xs) {
                Text("Your AI patient")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
                Text(scenario.patientName)
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)

                Button {
                    CouchHaptics.tap()
                    onQuickRep()
                } label: {
                    HStack(spacing: CouchTheme.Spacing.xs) {
                        Image(systemName: "waveform")
                            .accessibilityHidden(true)
                        Text("Quick rep")
                            .font(CouchTheme.Typography.pill)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, CouchTheme.Spacing.md)
                    .padding(.vertical, CouchTheme.Spacing.sm - 2)
                    .background(Capsule().fill(CouchTheme.textPrimary))
                }
                .buttonStyle(.couchPress)
                .accessibilityLabel("Start quick rep with \(scenario.patientName)")
            }
            Spacer()
        }
        .padding(.vertical, CouchTheme.Spacing.sm - 2)
    }

    private var avatarRing: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.85)
                .stroke(CouchTheme.success, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 74, height: 74)
                .rotationEffect(.degrees(-90))
                .accessibilityHidden(true)

            ScenarioPortraitView(scenario: scenario, crop: .avatar(60))
        }
        .overlay(alignment: .bottom) {
            Text("\(remaining) reps left")
                .font(.system(size: 10, weight: .semibold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
                .foregroundStyle(CouchTheme.textSecondary)
                .offset(y: 16)
        }
    }
}

// MARK: - State of mind

private struct StateOfMindSection: View {
    let repsDone: Int
    let repsGoal: Int
    var onCheckup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Text("Your Practice Plan")
                .font(CouchTheme.Typography.sectionTitle)
                .foregroundStyle(CouchTheme.textPrimary)

            VStack(spacing: 0) {
                row(
                    title: "Complete \(repsGoal) reps",
                    trailing: "\(min(repsDone, repsGoal))/\(repsGoal)",
                    trailingColor: CouchTheme.textSecondary,
                    trailingMonospaced: true,
                    done: repsDone >= repsGoal
                )
                Divider().overlay(CouchTheme.divider)
                row(
                    title: "Confidence check-up",
                    trailing: nil,
                    trailingColor: CouchTheme.primary,
                    action: onCheckup
                )
            }
            .padding(CouchTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.panel, style: .continuous)
                    .fill(CouchTheme.surfaceMuted)
            )

            Label("Get a personalised report on how your reps are landing.", systemImage: "list.clipboard")
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.textMuted)
        }
    }

    @ViewBuilder
    private func row(
        title: String,
        trailing: String?,
        trailingColor: Color,
        trailingMonospaced: Bool = false,
        done: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: CouchTheme.Spacing.md) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(done ? CouchTheme.success : CouchTheme.textMuted)
                .symbolEffect(.bounce, value: done)
                .contentTransition(.symbolEffect(.replace))
                .accessibilityHidden(true)
            Text(title)
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(
                        trailingMonospaced
                            ? CouchTheme.Typography.bodyEmphasized.monospacedDigit()
                            : CouchTheme.Typography.bodyEmphasized
                    )
                    .contentTransition(trailingMonospaced ? .numericText() : .identity)
                    .foregroundStyle(trailingColor)
            } else if let action {
                Button {
                    CouchHaptics.tap()
                    action()
                } label: {
                    Text("Start")
                        .font(CouchTheme.Typography.pill)
                        .foregroundStyle(CouchTheme.primary)
                        .padding(.horizontal, CouchTheme.Spacing.md)
                        .padding(.vertical, CouchTheme.Spacing.xs + 1)
                        .background(
                            Capsule().fill(Color.white)
                                .couchElevation(.sm)
                        )
                }
                .buttonStyle(.couchPress)
                .accessibilityLabel("Start \(title)")
            }
        }
        .padding(.vertical, CouchTheme.Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Today's focus

private struct TodaysFocusCard: View {
    let debrief: Debrief?

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Text("Today's focus")
                .font(CouchTheme.Typography.sectionTitle)
                .foregroundStyle(CouchTheme.textPrimary)

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                HStack(spacing: CouchTheme.Spacing.xs + 2) {
                    chip(text: "Timing")
                    chip(text: "~10 min")
                }
                .accessibilityElement(children: .combine)
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CouchTheme.Spacing.lg)
            .frame(minHeight: 180, alignment: .bottomLeading)
            .background(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.sheet, style: .continuous)
                    .fill(CouchTheme.accentGradient)
            )
        }
    }

    private func chip(text: String) -> some View {
        Text(text)
            .font(CouchTheme.Typography.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, CouchTheme.Spacing.sm)
            .padding(.vertical, CouchTheme.Spacing.xxs)
            .background(Capsule().fill(.white.opacity(0.22)))
    }

    private var title: String {
        if let debrief, !debrief.microDrillTitle.isEmpty {
            return debrief.microDrillTitle
        }
        return "When to Reflect (And When Silence Works Better)"
    }
}

// MARK: - Confidence check-up sheet (standalone, lightweight)

private struct ConfidenceCheckupSheet: View {
    var onClose: () -> Void

    @State private var selected: Int?

    private let options: [(Int, String)] = [
        (1, "Still nervous"),
        (2, "A little steadier"),
        (3, "Noticeably more ready"),
        (4, "I'd take a real session today"),
        (5, "Bring it on")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            Text("How ready do you feel right now?")
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
            Text("A quick gut-check between reps. Nothing gets shared.")
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textSecondary)

            VStack(spacing: CouchTheme.Spacing.sm) {
                ForEach(options, id: \.0) { option in
                    PillOption(
                        label: option.1,
                        isSelected: selected == option.0
                    ) { selected = option.0 }
                }
            }

            Spacer(minLength: 0)

            PrimaryButton(title: "Save", isEnabled: selected != nil) {
                onClose()
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
    }
}

// MARK: - Scroll transition helper

private extension View {
    /// Subtle depth for Home cards: settle into place on entry, soften on
    /// scroll-out. Works for vertical scrolling only.
    func homeCardScrollTransition() -> some View {
        scrollTransition(
            topLeading: .animated(.easeOut(duration: CouchMotion.small)),
            bottomTrailing: .animated(.easeIn(duration: CouchMotion.press))
        ) { view, phase in
            view
                .opacity(phase.isIdentity ? 1 : 0.85)
                .scaleEffect(phase.isIdentity ? 1 : 0.97)
        }
    }
}

// MARK: - Streak helper (used by HistoryView)

enum StreakCounter {
    static func consecutiveDays(events: [StreakEvent], today: Date = .now) -> Int {
        let calendar = Calendar.current
        let keyToday = StreakEvent.key(for: today)
        let allKeys = Set(events.map(\.dayKey))
        guard !allKeys.isEmpty else { return 0 }
        var count = 0
        var cursor = today
        while true {
            let key = StreakEvent.key(for: cursor)
            if allKeys.contains(key) {
                count += 1
            } else if count > 0 || key != keyToday {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
            if count > 365 { break }
        }
        return count
    }
}

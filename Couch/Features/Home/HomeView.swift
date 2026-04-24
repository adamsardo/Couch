import SwiftData
import SwiftUI

/// Practice-first home. The first screen gives one dominant action: run the
/// next rep. Progress stays visible but secondary and private.
struct HomeView: View {
    @Bindable var profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]
    @Query(filter: #Predicate<Session> { $0.statusRaw == "completed" }, sort: \Session.startedAt, order: .reverse) private var sessions: [Session]
    @Query(sort: \StreakEvent.day, order: .reverse) private var streakEvents: [StreakEvent]

    @State private var presentedScenario: Scenario?
    @State private var presentedSessionMode: SessionMode = .voice
    @State private var showCheckpoint = false

    private var primaryScenario: Scenario? {
        scenarios.first(where: { $0.id == ScenarioCatalog.marcus.id }) ?? scenarios.first
    }

    private var lastCompletedSession: Session? {
        sessions.first(where: { $0.debrief?.isComplete == true })
    }

    private var lastDebrief: Debrief? { lastCompletedSession?.debrief }

    private var completedThisWeek: Int {
        let calendar = Calendar.current
        guard let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)) else {
            return 0
        }
        return sessions.filter { $0.startedAt >= start }.count
    }

    private var streakDays: Int { StreakCounter.consecutiveDays(events: streakEvents) }

    private var averageConfidence: Double {
        let values = sessions
            .prefix(7)
            .compactMap { $0.debrief?.confidenceAfter }
            .map(Double.init)
        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }

    private var activeDayKeys: Set<String> {
        Set(streakEvents.map(\.dayKey))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
                greeting

                if let scenario = primaryScenario {
                    FeaturedScenarioCard(
                        scenario: scenario,
                        ctaTitle: "Run the rep",
                        subtitle: scenario.summary,
                        onStart: { startSession(with: scenario) }
                    )
                    .homeCardScrollTransition()
                }

                rings.homeCardScrollTransition()
                calendarCard.homeCardScrollTransition()

                if profile.ahaShown == false,
                   lastDebrief != nil,
                   let stressor = profile.topStressor.flatMap(FrictionStressor.init) {
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

                Button {
                    CouchHaptics.tap()
                    showCheckpoint = true
                } label: {
                    HStack(spacing: CouchTheme.Spacing.sm) {
                        Image(systemName: CouchIcons.dialMeter)
                            .font(.footnote.weight(.bold))
                        Text("Private confidence check")
                            .font(CouchTheme.Typography.bodyEmphasized)
                        Spacer()
                        Image(systemName: CouchIcons.arrowRight)
                            .font(.footnote.weight(.bold))
                    }
                    .foregroundStyle(CouchTheme.textPrimary)
                    .padding(CouchTheme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: CouchTheme.Radius.panel, style: .continuous)
                            .fill(CouchTheme.blushSoft)
                    )
                }
                .buttonStyle(.couchPress)
                .homeCardScrollTransition()
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
            .padding(.top, CouchTheme.Spacing.md)
            .padding(.bottom, CouchTheme.Spacing.xl)
            .animation(CouchMotion.stateChange, value: profile.ahaShown)
        }
        .background(CouchTheme.background.ignoresSafeArea())
        .couchBottomClearance(120)
        .fullScreenCover(item: $presentedScenario) { scenario in
            SessionContainer(
                scenario: scenario,
                mode: presentedSessionMode,
                onClose: { presentedScenario = nil }
            )
        }
        .sheet(isPresented: $showCheckpoint) {
            ConfidenceCheckupSheet { showCheckpoint = false }
                .presentationDetents([.height(620), .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Greeting

    private var greeting: some View {
        HStack(alignment: .center, spacing: CouchTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.xxs) {
                Text(greetingEyebrow)
                    .font(CouchTheme.Typography.eyebrow)
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundStyle(CouchTheme.primary)
                Text(greetingHeadline)
                    .font(CouchTheme.Typography.displayHeavy)
                    .foregroundStyle(CouchTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                Text("Low stakes reps for high stakes conversations.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: CouchTheme.Spacing.sm)
            Image("mascot-compact")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
        }
    }

    private var greetingEyebrow: String {
        "Today's plan"
    }

    private var greetingHeadline: String {
        let name = profile.name?.trimmingCharacters(in: .whitespaces)
        if let name, !name.isEmpty {
            return "You've got this, \(name)."
        }
        return "You've got this."
    }

    // MARK: - Rings

    private var rings: some View {
        HStack(spacing: CouchTheme.Spacing.md) {
            GoRing(
                value: Double(completedThisWeek),
                max: Double(max(profile.weeklyRepGoal, 1)),
                label: "Reps",
                caption: "this week",
                fillColor: CouchTheme.primary
            )
            GoRing(
                value: Double(streakDays),
                max: 7,
                label: "Streak",
                caption: streakDays == 1 ? "day" : "days",
                fillColor: CouchTheme.lavender
            )
            GoRing(
                value: averageConfidence,
                max: 5,
                label: "Confidence",
                caption: "avg / 5",
                fillColor: CouchTheme.success,
                integerValue: false
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calendar card

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            HStack {
                Label("Private progress", systemImage: CouchIcons.lock)
                    .font(CouchTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(CouchTheme.textMuted)
                Spacer()
                Text("\(completedThisWeek) / \(profile.weeklyRepGoal)")
                    .font(CouchTheme.Typography.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(CouchTheme.textSecondary)
                    .contentTransition(.numericText())
            }
            CalendarStripView(activeDayKeys: activeDayKeys)
        }
        .padding(CouchTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CouchTheme.Radius.panel, style: .continuous)
                .fill(CouchTheme.surfaceMuted)
        )
    }

    // MARK: - Helpers

    private func startSession(with scenario: Scenario) {
        presentedSessionMode = profile.defaultSessionMode
        presentedScenario = scenario
    }
}

// MARK: - Next skill drill

private struct TodaysFocusCard: View {
    let debrief: Debrief?

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Text("Next skill drill")
                .font(CouchTheme.Typography.sectionTitle)
                .foregroundStyle(CouchTheme.textPrimary)

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                HStack(spacing: CouchTheme.Spacing.xs + 2) {
                    chip(text: "Micro-drill")
                    chip(text: "5-10 min")
                }
                .accessibilityElement(children: .combine)
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(CouchTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CouchTheme.Spacing.lg)
            .frame(minHeight: 180, alignment: .bottomLeading)
            .background(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.sheet, style: .continuous)
                    .fill(CouchTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.sheet, style: .continuous)
                    .strokeBorder(CouchTheme.divider, lineWidth: 1)
            )
            .couchElevation(.sm)
        }
    }

    private func chip(text: String) -> some View {
        Text(text)
            .font(CouchTheme.Typography.caption.weight(.semibold))
            .foregroundStyle(CouchTheme.primaryStrong)
            .padding(.horizontal, CouchTheme.Spacing.sm)
            .padding(.vertical, CouchTheme.Spacing.xxs)
            .background(Capsule().fill(CouchTheme.primarySoft.opacity(0.6)))
    }

    private var title: String {
        if let debrief, !debrief.microDrillTitle.isEmpty {
            return debrief.microDrillTitle
        }
        return "Explore feelings a little deeper."
    }
}

// MARK: - Confidence check-up sheet (kept)

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
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: CouchTheme.Spacing.xs) {
                        Text("How ready do you feel right now?")
                            .font(CouchTheme.Typography.titleHeavy)
                            .foregroundStyle(CouchTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("A quick gut-check between reps. Nothing gets shared.")
                            .font(CouchTheme.Typography.body)
                            .foregroundStyle(CouchTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: CouchTheme.Spacing.sm) {
                        ForEach(options, id: \.0) { option in
                            PillOption(
                                label: option.1,
                                isSelected: selected == option.0
                            ) { selected = option.0 }
                        }
                    }
                }
                .padding(CouchTheme.Spacing.lg)
            }

            PrimaryButton(title: "Save", isEnabled: selected != nil) {
                onClose()
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
            .padding(.bottom, CouchTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .preferredColorScheme(.light)
    }
}

// MARK: - Scroll transition helper

private extension View {
    /// Subtle depth for Home cards.
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

// MARK: - Streak helper (used by Progress)

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

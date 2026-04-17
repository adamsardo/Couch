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

    private var primaryScenario: Scenario? {
        scenarios.first(where: { $0.id == ScenarioCatalog.marcus.id }) ?? scenarios.first
    }

    private var lastCompletedSession: Session? {
        sessions.first(where: { $0.status == .completed && $0.debrief != nil })
    }

    private var lastDebrief: Debrief? { lastCompletedSession?.debrief }

    private var streakDays: Int { StreakCounter.consecutiveDays(events: streakEvents) }

    var body: some View {
        ScrollView {
            VStack(spacing: CouchTheme.Spacing.md) {
                HomeHeader(profile: profile, streak: streakDays)

                if profile.ahaShown == false, lastDebrief != nil, let stressor = profile.topStressor.flatMap(FrictionStressor.init) {
                    AhaMomentCard(stressor: stressor) {
                        profile.ahaShown = true
                        try? modelContext.save()
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                if let scenario = primaryScenario {
                    ResumeCard(
                        scenario: scenario,
                        lastSession: lastCompletedSession,
                        action: { startSession(with: scenario, mode: .voice) }
                    )
                    SuggestedScenarioCard(
                        scenario: scenario,
                        action: { startSession(with: scenario, mode: .voice) }
                    )
                }

                if let drill = lastDebrief {
                    MicroFocusCard(title: drill.microDrillTitle, bodyText: drill.microDrillBody)
                }

                if let drill = lastDebrief {
                    RecentHighlightsCard(strengths: drill.strengths)
                }

                StreakView(days: streakDays)
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
            .padding(.vertical, CouchTheme.Spacing.lg)
            .animation(.easeInOut(duration: 0.25), value: profile.ahaShown)
        }
        .background(CouchTheme.background.ignoresSafeArea())
        .fullScreenCover(item: $presentedScenario) { scenario in
            SessionContainer(
                scenario: scenario,
                mode: presentedSessionMode,
                onClose: { presentedScenario = nil }
            )
        }
    }

    private func startSession(with scenario: Scenario, mode: SessionMode) {
        presentedSessionMode = mode
        presentedScenario = scenario
    }
}

private struct SessionContainer: View {
    let scenario: Scenario
    let mode: SessionMode
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            SessionIntroBridge(scenario: scenario, mode: mode, onClose: onClose)
        }
    }
}

private struct SessionIntroBridge: View {
    let scenario: Scenario
    let mode: SessionMode
    var onClose: () -> Void

    @State private var didStart = false

    var body: some View {
        if didStart {
            ConversationView(scenario: scenario, mode: mode, onClose: onClose)
        } else {
            SessionIntroView(scenario: scenario) {
                didStart = true
            }
        }
    }
}

private struct HomeHeader: View {
    let profile: UserProfile
    let streak: Int

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("One rep tonight is enough.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
            Spacer()
            if streak > 0 {
                StreakPill(days: streak)
            }
        }
        .padding(.bottom, CouchTheme.Spacing.sm)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Morning."
        case 12..<17: return "Afternoon."
        case 17..<22: return "Evening."
        default: return "Late night."
        }
    }
}

private struct StreakPill: View {
    let days: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(CouchTheme.accent)
            Text("\(days) day\(days == 1 ? "" : "s")")
                .font(CouchTheme.Typography.pill)
                .foregroundStyle(CouchTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(CouchTheme.surface))
        .overlay(Capsule().strokeBorder(CouchTheme.divider, lineWidth: 1))
    }
}

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

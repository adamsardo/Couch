import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(filter: #Predicate<Session> { $0.statusRaw == "completed" }, sort: \Session.startedAt, order: .reverse) private var sessions: [Session]
    @Query(sort: \StreakEvent.day, order: .reverse) private var streakEvents: [StreakEvent]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var window: Window = .sevenDays

    enum Window: Hashable { case sevenDays, thirtyDays, all }

    private var streakDays: Int { StreakCounter.consecutiveDays(events: streakEvents) }

    private var completedSessions: [Session] {
        sessions
    }

    private var filteredSessions: [Session] {
        let calendar = Calendar.current
        switch window {
        case .all:
            return completedSessions
        case .sevenDays:
            guard let start = calendar.date(byAdding: .day, value: -7, to: .now) else { return completedSessions }
            return completedSessions.filter { $0.startedAt >= start }
        case .thirtyDays:
            guard let start = calendar.date(byAdding: .day, value: -30, to: .now) else { return completedSessions }
            return completedSessions.filter { $0.startedAt >= start }
        }
    }

    private var totalReps: Int { filteredSessions.count }

    private var averageDuration: TimeInterval {
        let completed = filteredSessions
        guard !completed.isEmpty else { return 0 }
        let total = completed.reduce(0.0) { $0 + $1.duration }
        return total / Double(completed.count)
    }

    private var averageConfidence: Double {
        let values = filteredSessions.compactMap { $0.debrief?.confidenceAfter }.map(Double.init)
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var confidenceSeries: [Double] {
        // Oldest → newest for the chart.
        filteredSessions
            .reversed()
            .compactMap { $0.debrief?.confidenceAfter }
            .map(Double.init)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CouchTheme.Spacing.lg) {
                    StreakView(days: streakDays)

                    filterCard
                    statTiles
                    trendCard

                    if filteredSessions.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredSessions) { session in
                            SessionHistoryRow(session: session)
                                .scrollTransition(
                                    topLeading: .animated(.easeOut(duration: CouchMotion.small)),
                                    bottomTrailing: .animated(.easeIn(duration: CouchMotion.press))
                                ) { view, phase in
                                    view
                                        .opacity(phase.isIdentity ? 1 : 0.8)
                                        .scaleEffect(phase.isIdentity ? 1 : 0.97)
                                }
                        }
                    }
                }
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .padding(.top, CouchTheme.Spacing.md)
                .padding(.bottom, CouchTheme.Spacing.xl)
                .animation(CouchMotion.stateChange, value: window)
            }
            .background(CouchTheme.background.ignoresSafeArea())
            .couchBottomClearance(120)
            .navigationTitle("Progress")
            .toolbarBackground(CouchTheme.background, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Filter

    private var filterCard: some View {
        HStack {
            ChipSegment<Window>(
                options: [
                    .init(id: .sevenDays, label: "7 days"),
                    .init(id: .thirtyDays, label: "30 days"),
                    .init(id: .all, label: "All time")
                ],
                selection: $window
            )
            Spacer()
        }
    }

    // MARK: - Stat tiles

    private var statTiles: some View {
        HStack(spacing: CouchTheme.Spacing.sm) {
            StatTile(
                value: "\(totalReps)",
                caption: "Reps"
            )
            StatTile(
                value: formattedDuration,
                caption: "Avg duration"
            )
            StatTile(
                value: averageConfidence == 0 ? "–" : String(format: "%.1f", averageConfidence),
                caption: "Avg confidence"
            )
        }
    }

    private var formattedDuration: String {
        guard averageDuration > 0 else { return "–" }
        return TimeFormatting.mmss(averageDuration)
    }

    // MARK: - Trend chart

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            HStack {
                Label("Earned confidence", systemImage: CouchIcons.chart)
                    .font(CouchTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(CouchTheme.textMuted)
                Spacer()
                Text("\(confidenceSeries.count) reps")
                    .font(CouchTheme.Typography.caption.monospacedDigit())
                    .foregroundStyle(CouchTheme.textMuted)
                    .contentTransition(.numericText())
            }
            ConfidenceTrendChart(values: confidenceSeries)
        }
        .padding(CouchTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CouchTheme.Radius.panel, style: .continuous)
                .fill(CouchTheme.surfaceMuted)
        )
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: CouchTheme.Spacing.sm) {
            Image(systemName: CouchIcons.sparkles)
                .font(.system(size: 32))
                .foregroundStyle(CouchTheme.primary)
                .symbolEffect(
                    .pulse,
                    options: .repeating.speed(0.5),
                    isActive: !reduceMotion
                )
                .accessibilityHidden(true)
            Text("No reps yet.")
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.textPrimary)
            Text("Run one low-stakes conversation and start building confidence.")
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CouchTheme.Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}

private struct SessionHistoryRow: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            HStack {
                Text(session.scenario?.patientName ?? "Rep")
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(CouchTheme.textPrimary)
                Spacer()
                Text(TimeFormatting.relativeDay(session.endedAt ?? session.startedAt))
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
            }

            HStack(spacing: CouchTheme.Spacing.sm) {
                miniStat(value: TimeFormatting.mmss(session.duration), caption: "Duration")
                miniStat(value: "\(session.turns.count)", caption: "Turns")
                miniStat(value: "\(session.rapportFinal)", caption: "Rapport")
            }

            if let debrief = session.debrief {
                if let first = debrief.strengths.first {
                    Label(first, systemImage: CouchIcons.checkmarkCircle)
                        .font(CouchTheme.Typography.caption)
                        .foregroundStyle(CouchTheme.success)
                        .lineLimit(2)
                }
                if !debrief.microDrillTitle.isEmpty {
                    Label(debrief.microDrillTitle, systemImage: CouchIcons.target)
                        .font(CouchTheme.Typography.caption)
                        .foregroundStyle(CouchTheme.primary)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .couchGlassCard()
        .accessibilityElement(children: .combine)
    }

    private func miniStat(value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .heavy).monospacedDigit())
                .foregroundStyle(CouchTheme.textPrimary)
                .contentTransition(.numericText())
            Text(caption)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CouchTheme.Spacing.sm)
        .padding(.vertical, CouchTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CouchTheme.Radius.bubble, style: .continuous)
                .fill(CouchTheme.surfaceMuted)
        )
    }
}

#Preview {
    HistoryView()
        .modelContainer(AppModelContainer.previewContainer())
}

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \Session.startedAt, order: .reverse) private var sessions: [Session]
    @Query(sort: \StreakEvent.day, order: .reverse) private var streakEvents: [StreakEvent]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var streakDays: Int { StreakCounter.consecutiveDays(events: streakEvents) }
    private var completedSessions: [Session] { sessions.filter { $0.status == .completed } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CouchTheme.Spacing.lg) {
                    StreakView(days: streakDays)

                    if completedSessions.isEmpty {
                        emptyState
                    } else {
                        ForEach(completedSessions) { session in
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
            }
            .background(CouchTheme.background.ignoresSafeArea())
            .navigationTitle("History")
        }
    }

    private var emptyState: some View {
        VStack(spacing: CouchTheme.Spacing.sm) {
            Image(systemName: "sparkles")
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
            Text("Finish your first rep to see it here with its strengths and next moves.")
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
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.xs) {
            HStack {
                Text(session.scenario?.patientName ?? "Rep")
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(CouchTheme.textPrimary)
                Spacer()
                Text(TimeFormatting.relativeDay(session.endedAt ?? session.startedAt))
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
            }
            if let debrief = session.debrief {
                if let first = debrief.strengths.first {
                    Label(first, systemImage: "checkmark.circle.fill")
                        .font(CouchTheme.Typography.caption)
                        .foregroundStyle(CouchTheme.success)
                        .lineLimit(2)
                }
                if !debrief.microDrillTitle.isEmpty {
                    Label(debrief.microDrillTitle, systemImage: "target")
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
}

#Preview {
    HistoryView()
        .modelContainer(AppModelContainer.previewContainer())
}

import SwiftUI

struct ResumeCard: View {
    let scenario: Scenario
    let lastSession: Session?
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(CouchTheme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(CouchTheme.Typography.cardTitle)
                        .foregroundStyle(CouchTheme.textPrimary)
                    Text(subline)
                        .font(CouchTheme.Typography.caption)
                        .foregroundStyle(CouchTheme.textSecondary)
                }
                Spacer()
            }
            PrimaryButton(title: cta, systemImage: "waveform") { action() }
        }
        .frame(maxWidth: .infinity)
        .couchGlassCard(tint: CouchTheme.primary.opacity(0.08))
    }

    private var headline: String {
        lastSession == nil ? "Your first rep is waiting." : "Pick up where you left off."
    }

    private var subline: String {
        if let last = lastSession, let endedAt = last.endedAt {
            return "Last rep with \(scenario.patientName) — \(TimeFormatting.relativeDay(endedAt))"
        }
        return "Marcus is ready when you are."
    }

    private var cta: String {
        lastSession == nil ? "Start first rep" : "Start a new rep"
    }
}

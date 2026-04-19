import SwiftUI

/// One-time post-first-debrief card that mirrors the user's onboarding-stated friction
/// back at them with the friction explicitly removed. This is the PRD §11 aha payoff.
struct AhaMomentCard: View {
    let stressor: FrictionStressor
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
            HStack(alignment: .top) {
                Label("That just happened", systemImage: "sparkles")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.accentOnLight)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CouchTheme.textMuted)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(CouchTheme.surface))
                }
                .accessibilityLabel("Dismiss")
            }
            Text(stressor.ahaPayoff)
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
            Text("This is the loop. Quick, private reps until it feels natural in the room.")
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .couchGlassCard(tint: CouchTheme.accent.opacity(0.22))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        AhaMomentCard(stressor: .timePoor, onDismiss: {})
        AhaMomentCard(stressor: .logistics, onDismiss: {})
        AhaMomentCard(stressor: .anxiety, onDismiss: {})
    }
    .padding()
    .background(CouchTheme.background)
}

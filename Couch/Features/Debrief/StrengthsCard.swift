import SwiftUI

struct StrengthsCard: View {
    let strengths: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
            Label("Strengths", systemImage: "leaf.fill")
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.success)
            ForEach(Array(strengths.enumerated()), id: \.offset) { _, strength in
                HStack(alignment: .top, spacing: CouchTheme.Spacing.sm + 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CouchTheme.success)
                        .font(.title3)
                        .accessibilityHidden(true)
                    Text(strength)
                        .font(CouchTheme.Typography.body)
                        .foregroundStyle(CouchTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity)
        .couchGlassCard(tint: CouchTheme.success.opacity(0.1))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    StrengthsCard(strengths: [
        "You reflected what Marcus said about Jess instead of jumping to interpretation.",
        "You asked one question and then waited — rare in a first session.",
        "You normalised the visit without minimising what brought him in."
    ])
    .padding()
    .background(CouchTheme.background)
}

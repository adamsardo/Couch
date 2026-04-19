import SwiftUI

struct SuggestedScenarioCard: View {
    let scenario: Scenario
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Label("Today's suggestion", systemImage: "sparkles")
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.accentOnLight)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(CouchTheme.primary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(scenario.patientName), \(scenario.patientAge)")
                        .font(CouchTheme.Typography.cardTitle)
                        .foregroundStyle(CouchTheme.textPrimary)
                    Text(scenario.summary)
                        .font(CouchTheme.Typography.body)
                        .foregroundStyle(CouchTheme.textSecondary)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(scenario.tags, id: \.self) { tag in
                    Text(tag)
                        .font(CouchTheme.Typography.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(CouchTheme.surfaceMuted))
                        .foregroundStyle(CouchTheme.textSecondary)
                }
            }
            Button(action: {
                CouchHaptics.tap()
                action()
            }) {
                HStack {
                    Text("Start this rep")
                        .font(CouchTheme.Typography.bodyEmphasized)
                        .foregroundStyle(CouchTheme.primaryStrong)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(CouchTheme.primaryStrong)
                        .accessibilityHidden(true)
                }
                .padding(.top, 8)
            }
            .buttonStyle(.couchPress)
            .accessibilityLabel("Start session with \(scenario.patientName)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .couchGlassCard()
    }
}

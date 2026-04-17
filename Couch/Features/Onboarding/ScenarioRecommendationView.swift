import SwiftUI

struct ScenarioRecommendationView: View {
    @Bindable var state: OnboardingState

    private let blueprint = ScenarioCatalog.marcus

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Text("Your first rep")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("We picked something gentle to start. You can change scenarios later.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(CouchTheme.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(blueprint.patientName), \(blueprint.patientAge)")
                            .font(CouchTheme.Typography.cardTitle)
                            .foregroundStyle(CouchTheme.textPrimary)
                        Text(blueprint.title)
                            .font(CouchTheme.Typography.caption)
                            .foregroundStyle(CouchTheme.textSecondary)
                    }
                }
                Text(blueprint.summary)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textPrimary)
                Label(blueprint.calmingCue, systemImage: "leaf.fill")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.success)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .couchGlassCard(tint: CouchTheme.accent.opacity(0.1))

            Spacer()

            PrimaryButton(title: "I'm ready", systemImage: "arrow.right") {
                state.advance(to: .microphone)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .navigationTitle("First rep")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { ScenarioRecommendationView(state: OnboardingState()) }
}

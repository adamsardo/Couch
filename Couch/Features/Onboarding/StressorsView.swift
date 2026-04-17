import SwiftUI

struct StressorsView: View {
    let state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Text("What's most challenging about practising right now?")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("Select all that apply — your answers stay on your device.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }

            ScrollView {
                VStack(spacing: CouchTheme.Spacing.sm) {
                    ForEach(FrictionStressor.allCases) { stressor in
                        PillOption(
                            label: stressor.rawValue,
                            isSelected: state.stressors.contains(stressor)
                        ) {
                            toggle(stressor)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            PrimaryButton(title: "Continue", isEnabled: !state.stressors.isEmpty) {
                state.advance(to: .goals)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
    }

    private func toggle(_ stressor: FrictionStressor) {
        if state.stressors.contains(stressor) {
            state.stressors.remove(stressor)
        } else {
            state.stressors.insert(stressor)
        }
    }
}

#Preview {
    NavigationStack { StressorsView(state: OnboardingState()) }
}

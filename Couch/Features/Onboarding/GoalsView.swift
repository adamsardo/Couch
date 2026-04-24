import SwiftUI

struct GoalsView: View {
    let state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Text("What do you want the reps to build?")
                    .font(CouchTheme.Typography.titleHeavy)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("Choose one or more skills. No lectures, just practice.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }

            ScrollView {
                VStack(spacing: CouchTheme.Spacing.sm) {
                    ForEach(PracticeGoal.allCases) { goal in
                        PillOption(
                            label: goal.rawValue,
                            isSelected: state.goals.contains(goal)
                        ) {
                            toggle(goal)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            PrimaryButton(title: "Continue", isEnabled: !state.goals.isEmpty) {
                state.advance(to: .quickProfile)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
    }

    private func toggle(_ goal: PracticeGoal) {
        if state.goals.contains(goal) {
            state.goals.remove(goal)
        } else {
            state.goals.insert(goal)
        }
    }
}

#Preview {
    NavigationStack { GoalsView(state: OnboardingState()) }
}

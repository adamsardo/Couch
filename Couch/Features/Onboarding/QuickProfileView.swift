import SwiftUI

struct QuickProfileView: View {
    let state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Text("A little about your placement.")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("Two quick taps. Skip if you'd rather just dive in.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
                    section(title: "Year level") {
                        VStack(spacing: CouchTheme.Spacing.sm) {
                            ForEach(YearLevel.allCases) { option in
                                PillOption(
                                    label: option.rawValue,
                                    isSelected: state.yearLevel == option
                                ) {
                                    state.yearLevel = option
                                }
                            }
                        }
                    }
                    section(title: "Placement is…") {
                        VStack(spacing: CouchTheme.Spacing.sm) {
                            ForEach(PlacementWindow.allCases) { option in
                                PillOption(
                                    label: option.rawValue,
                                    isSelected: state.placementWindow == option
                                ) {
                                    state.placementWindow = option
                                }
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            VStack(spacing: CouchTheme.Spacing.sm) {
                PrimaryButton(title: "Continue") {
                    state.advance(to: .scienceChart)
                }
                Button("Skip for now") {
                    state.yearLevel = nil
                    state.placementWindow = nil
                    state.advance(to: .scienceChart)
                }
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.textSecondary)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Text(title)
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.textPrimary)
            content()
        }
    }
}

#Preview {
    NavigationStack { QuickProfileView(state: OnboardingState()) }
}

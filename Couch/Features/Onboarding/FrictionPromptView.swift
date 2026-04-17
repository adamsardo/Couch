import SwiftUI

struct FrictionPromptView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Text("What gets in the way of practising right now?")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("Pick whichever feels biggest. We'll show you how Couch removes it.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: CouchTheme.Spacing.sm) {
                ForEach(FrictionStressor.allCases) { stressor in
                    FrictionRow(
                        stressor: stressor,
                        isSelected: state.topStressor == stressor
                    ) {
                        state.topStressor = stressor
                    }
                }
            }

            Spacer()

            PrimaryButton(title: "Continue") {
                state.advance(to: .scenarioRecommendation)
            }
            .disabled(state.topStressor == nil)
            .opacity(state.topStressor == nil ? 0.5 : 1)
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .navigationTitle("Friction")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FrictionRow: View {
    let stressor: FrictionStressor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            CouchHaptics.tap()
            action()
        }) {
            HStack(spacing: CouchTheme.Spacing.md) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundStyle(isSelected ? CouchTheme.primary : CouchTheme.textMuted)
                    .font(.title3)
                Text(stressor.rawValue)
                    .font(CouchTheme.Typography.bodyEmphasized)
                    .foregroundStyle(CouchTheme.textPrimary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .couchGlassCard(tint: isSelected ? CouchTheme.primary.opacity(0.1) : nil)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(stressor.rawValue)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview {
    NavigationStack { FrictionPromptView(state: OnboardingState()) }
}

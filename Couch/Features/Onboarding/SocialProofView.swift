import SwiftUI

struct SocialProofView: View {
    let state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            Spacer(minLength: 0)

            SocialProofGrid()

            Spacer(minLength: 0)

            HighlightedText(
                fullText: "Our science-backed practice reps help 9,000+ students show up calm.",
                highlight: "show up calm",
                font: CouchTheme.Typography.title
            )

            PrimaryButton(title: "Continue") {
                state.advance(to: .stressors)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
    }
}

#Preview {
    NavigationStack { SocialProofView(state: OnboardingState()) }
}

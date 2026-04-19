import SwiftUI

/// Full-bleed blue marketing hero. White text, bright yellow highlight on
/// the key phrase, and a white pill CTA.
struct SocialProofView: View {
    let state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            Spacer(minLength: 0)

            SocialProofGrid(
                captionColor: .white.opacity(0.8),
                placeholderColor: .white.opacity(0.85)
            )

            Spacer(minLength: 0)

            HighlightedText(
                fullText: "Our science-backed practice reps help 9,000+ students show up calm.",
                highlight: "show up calm",
                font: CouchTheme.Typography.displayHeavy,
                highlightColor: CouchTheme.accent,
                baseColor: .white
            )

            PrimaryButton(title: "Continue", style: .onHero) {
                state.advance(to: .stressors)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.heroBackground.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack { SocialProofView(state: OnboardingState()) }
}

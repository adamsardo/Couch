import SwiftUI

/// Full-bleed violet marketing hero. White text, soft highlight on the
/// practice promise, and a cream CTA.
struct SocialProofView: View {
    let state: OnboardingState

    @ScaledMetric(relativeTo: .body) private var heroPadding: CGFloat = CouchTheme.Spacing.lg

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            Spacer(minLength: 0)

            SocialProofGrid(
                captionColor: .white.opacity(0.8),
                placeholderColor: .white.opacity(0.85)
            )

            Spacer(minLength: 0)

            HighlightedText(
                fullText: "Low stakes reps for high stakes conversations.",
                highlight: "Low stakes reps",
                font: CouchTheme.Typography.displayHeavy,
                highlightColor: CouchTheme.peachSoft,
                baseColor: .white
            )

            PrimaryButton(title: "Continue", style: .onHero) {
                state.advance(to: .stressors)
            }
        }
        .padding(heroPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.heroBackground.ignoresSafeArea())
        .couchStatusBar(.onHero)
    }
}

#Preview {
    NavigationStack { SocialProofView(state: OnboardingState()) }
}

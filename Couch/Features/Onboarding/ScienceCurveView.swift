import SwiftUI

/// Violet-hero practice-curve screen. White text, peach end-label on the
/// brand curve, cream pill CTA.
struct ScienceCurveView: View {
    let state: OnboardingState

    @ScaledMetric(relativeTo: .body) private var heroPadding: CGFloat = CouchTheme.Spacing.lg

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            Spacer(minLength: 0)

            SciencePathChart(appearance: .onHero)
                .padding(.top, CouchTheme.Spacing.md)

            Spacer(minLength: 0)

            HighlightedText(
                fullText: "\(headlineLead) is easier with short Couch reps.",
                highlight: headlineLead,
                font: CouchTheme.Typography.displayHeavy,
                highlightColor: CouchTheme.peachSoft,
                baseColor: .white
            )

            PrimaryButton(title: "Continue", style: .onHero) {
                state.advance(to: .personalising)
            }
        }
        .padding(heroPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.heroBackground.ignoresSafeArea())
        .couchStatusBar(.onHero)
    }

    private var headlineLead: String {
        state.goals.first?.rawValue ?? "Building confidence"
    }
}

#Preview {
    NavigationStack {
        ScienceCurveView(state: {
            let s = OnboardingState()
            s.goals = [.buildConfidence]
            return s
        }())
    }
}

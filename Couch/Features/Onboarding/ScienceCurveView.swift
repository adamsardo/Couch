import SwiftUI

/// Blue-hero science-curve marketing screen. White text, yellow end-label
/// on the brand curve, white pill CTA.
struct ScienceCurveView: View {
    let state: OnboardingState

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
                highlightColor: CouchTheme.accent,
                baseColor: .white
            )

            PrimaryButton(title: "Continue", style: .onHero) {
                state.advance(to: .personalising)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.heroBackground.ignoresSafeArea())
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

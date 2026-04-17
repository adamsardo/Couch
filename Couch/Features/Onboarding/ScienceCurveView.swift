import SwiftUI

struct ScienceCurveView: View {
    let state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            Spacer(minLength: 0)

            SciencePathChart()
                .padding(.top, CouchTheme.Spacing.md)

            Spacer(minLength: 0)

            HighlightedText(
                fullText: "\(headlineLead) is easier with short Couch reps.",
                highlight: headlineLead,
                font: CouchTheme.Typography.title
            )

            PrimaryButton(title: "Continue") {
                state.advance(to: .personalising)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
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

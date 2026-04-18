import SwiftData
import SwiftUI

struct PersonalisingView: View {
    let state: OnboardingState
    @Environment(\.modelContext) private var modelContext

    private let phases: [PersonalisingLoader.Phase] = [
        .init(label: "Analysing your profile…", duration: 1.2),
        .init(label: "Understanding your needs…", duration: 1.2),
        .init(label: "Finding your best first rep…", duration: 1.4)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            PieSpinner()
                .padding(.top, CouchTheme.Spacing.xl)

            Text("Personalising your experience…")
                .font(CouchTheme.Typography.display)
                .foregroundStyle(CouchTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, CouchTheme.Spacing.lg)
                .padding(.horizontal, CouchTheme.Spacing.lg)

            Spacer(minLength: 0)

            PersonalisingLoader(phases: phases, onFinished: onFinished)
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .padding(.bottom, CouchTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .navigationBarBackButtonHidden(true)
        .task { SeedData.ensureScenariosExist(in: modelContext) }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.white,
                CouchTheme.primarySoft.opacity(0.55),
                Color.white
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func onFinished() {
        guard !Task.isCancelled else { return }
        state.advance(to: .scenarioMatch)
    }
}

#Preview {
    NavigationStack { PersonalisingView(state: OnboardingState()) }
        .modelContainer(AppModelContainer.previewContainer())
}

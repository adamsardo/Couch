import SwiftData
import SwiftUI

struct PersonalisingView: View {
    let state: OnboardingState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            CouchTheme.accentGradient.ignoresSafeArea()

            VStack {
                Spacer()
                OrangeRingLoader()
                    .frame(height: 360)
                Spacer()
                Text(craftingCopy)
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CouchTheme.Spacing.lg)
                    .padding(.bottom, CouchTheme.Spacing.xl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await performWork() }
    }

    private var craftingCopy: String {
        let name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return "Crafting your first rep…"
        } else {
            return "Finding the right first rep for \(name)…"
        }
    }

    private func performWork() async {
        SeedData.ensureScenariosExist(in: modelContext)
        try? await Task.sleep(for: .seconds(3.8))
        guard !Task.isCancelled else { return }
        state.advance(to: .scenarioMatch)
    }
}

#Preview {
    NavigationStack { PersonalisingView(state: OnboardingState()) }
}

import SwiftData
import SwiftUI

struct ScenarioMatchView: View {
    let state: OnboardingState
    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]

    @State private var selectedID: String?

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Text("We found your best-fit first rep")
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CouchTheme.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CouchTheme.Spacing.md) {
                    ForEach(cards, id: \.id) { card in
                        ScenarioMatchCard(
                            name: card.name,
                            quote: card.quote,
                            fit: card.fit,
                            portraitAsset: card.portraitAsset,
                            isSelected: selectedID == card.id,
                            onTap: { select(card) }
                        )
                        .frame(width: 260)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, CouchTheme.Spacing.lg)
            }
            .scrollTargetBehavior(.viewAligned)

            Spacer()

            PrimaryButton(title: "Choose", isEnabled: selectedID != nil) {
                state.advance(to: .scenarioDetail)
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
        }
        .padding(.vertical, CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .task { preselectBestFit() }
    }

    private func select(_ card: CardModel) {
        guard card.fit != .comingSoon else { return }
        selectedID = card.id
    }

    private func preselectBestFit() {
        if selectedID == nil, let best = cards.first(where: { $0.fit == .best }) {
            selectedID = best.id
        }
    }

    private var cards: [CardModel] {
        let real = scenarios.map { scenario in
            CardModel(
                id: scenario.id,
                name: scenario.patientName,
                quote: scenario.calmingCue,
                fit: scenario.id == ScenarioCatalog.marcus.id ? .best : .good,
                portraitAsset: "scenario-\(scenario.id)"
            )
        }
        let placeholders = [
            CardModel(id: "coming-1", name: "Aisha", quote: "Help me stop spiralling.", fit: .comingSoon, portraitAsset: nil),
            CardModel(id: "coming-2", name: "Jamie", quote: "What if I'm not cut out for this?", fit: .comingSoon, portraitAsset: nil)
        ]
        return real + placeholders
    }

    private struct CardModel: Identifiable {
        let id: String
        let name: String
        let quote: String
        let fit: ScenarioMatchCard.Fit
        let portraitAsset: String?
    }
}

#Preview {
    NavigationStack { ScenarioMatchView(state: OnboardingState()) }
        .modelContainer(AppModelContainer.previewContainer())
}

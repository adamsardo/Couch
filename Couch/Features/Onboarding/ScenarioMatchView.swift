import SwiftData
import SwiftUI

struct ScenarioMatchView: View {
    let state: OnboardingState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.zoomNamespace) private var zoomNamespace
    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]

    @State private var selectedID: String?

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            header

            Text("Start with a realistic virtual patient")
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CouchTheme.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CouchTheme.Spacing.md) {
                    ForEach(cards, id: \.id) { card in
                        cardView(for: card)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, CouchTheme.Spacing.xl)
            }
            .scrollTargetBehavior(.viewAligned)

            Spacer(minLength: 0)

            PrimaryButton(title: "Choose first rep", isEnabled: selectedID != nil) {
                state.advance(to: .scenarioDetail)
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
        }
        .padding(.vertical, CouchTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .task { preselectBestFit() }
    }

    @ViewBuilder
    private func cardView(for card: CardModel) -> some View {
        let base = ScenarioMatchCard(
            name: card.name,
            quote: card.quote,
            fit: card.fit,
            portraitAsset: card.portraitAsset,
            isSelected: selectedID == card.id,
            onTap: { select(card) }
        )
        .frame(width: 280)
        .scrollTransition(
            topLeading: .animated(.easeOut(duration: CouchMotion.small)),
            bottomTrailing: .animated(.easeIn(duration: CouchMotion.press))
        ) { view, phase in
            view
                .opacity(phase.isIdentity ? 1 : 0.7)
                .scaleEffect(phase.isIdentity ? 1 : 0.95)
        }

        if selectedID == card.id, let zoomNamespace {
            base.matchedTransitionSource(id: "scenario-detail", in: zoomNamespace)
        } else {
            base
        }
    }

    private var header: some View {
        HStack {
            FloatingBackButton(background: CouchTheme.surfaceMuted) { dismiss() }
            Spacer()
        }
        .padding(.horizontal, CouchTheme.Spacing.md)
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
            CardModel(id: "avery", name: "Avery", quote: "Exploring self-worth and relationships", fit: .comingSoon, portraitAsset: "patient-avery"),
            CardModel(id: "zara", name: "Zara", quote: "Managing stress and expectations", fit: .comingSoon, portraitAsset: "patient-zara"),
            CardModel(id: "maya", name: "Maya", quote: "Navigating identity and life transitions", fit: .comingSoon, portraitAsset: "patient-maya")
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

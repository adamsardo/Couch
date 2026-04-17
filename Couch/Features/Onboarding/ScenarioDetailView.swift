import SwiftData
import SwiftUI

struct ScenarioDetailView: View {
    let state: OnboardingState
    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]

    private var scenario: Scenario? {
        scenarios.first(where: { $0.id == ScenarioCatalog.marcus.id }) ?? scenarios.first
    }

    var body: some View {
        Group {
            if let scenario {
                content(for: scenario)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CouchTheme.background)
            }
        }
    }

    @ViewBuilder
    private func content(for scenario: Scenario) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
                hero(for: scenario)

                VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                    Text("Meet \(scenario.patientName)")
                        .font(CouchTheme.Typography.display)
                        .foregroundStyle(CouchTheme.textPrimary)

                    VStack(alignment: .center, spacing: 4) {
                        Text(scenario.title.capitalized)
                            .font(CouchTheme.Typography.cardTitle)
                            .foregroundStyle(CouchTheme.textPrimary)
                        Text("AI simulated patient. Not a real person.")
                            .font(CouchTheme.Typography.caption)
                            .foregroundStyle(CouchTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CouchTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(CouchTheme.surfaceMuted)
                    )
                }

                Text("\u{201C}\(scenario.summary)\u{201D}")
                    .font(CouchTheme.Typography.body)
                    .italic()
                    .foregroundStyle(CouchTheme.textPrimary)

                VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                    Text("Notes from past reps")
                        .font(CouchTheme.Typography.cardTitle)
                        .foregroundStyle(CouchTheme.textPrimary)
                    ForEach(SampleReviews.all) { review in
                        reviewCard(review)
                    }
                }
            }
            .padding(CouchTheme.Spacing.lg)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Nice to meet you") {
                state.advance(to: .notifications)
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
            .padding(.bottom, CouchTheme.Spacing.md)
            .background(CouchTheme.background)
        }
        .background(CouchTheme.background)
    }

    private func hero(for scenario: Scenario) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: CouchTheme.Radius.card, style: .continuous)
                .fill(LinearGradient(
                    colors: [CouchTheme.primarySoft, CouchTheme.surfaceMuted],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(height: 260)
                .overlay(
                    Group {
                        if UIImage(named: "scenario-\(scenario.id)") != nil {
                            Image("scenario-\(scenario.id)")
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: CouchTheme.Radius.card, style: .continuous))
                        } else {
                            Text(String(scenario.patientName.prefix(1)))
                                .font(.system(size: 96, weight: .bold, design: .rounded))
                                .foregroundStyle(CouchTheme.textPrimary.opacity(0.3))
                        }
                    }
                )
        }
    }

    private func reviewCard(_ review: SampleReview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 2) {
                ForEach(0..<review.stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.footnote)
                        .foregroundStyle(CouchTheme.primary)
                }
            }
            Text(review.body)
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textPrimary)
            Text(review.date)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CouchTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CouchTheme.surfaceMuted)
        )
    }
}

struct SampleReview: Identifiable {
    let id = UUID()
    let stars: Int
    let body: String
    let date: String
}

enum SampleReviews {
    static let all: [SampleReview] = [
        SampleReview(
            stars: 5,
            body: "Example user feedback: Marcus made me slow down. Next session I remembered to breathe before jumping to reassurance.",
            date: "September 10, 2025"
        ),
        SampleReview(
            stars: 4,
            body: "Example user feedback: A useful first rep. I noticed I fill silence too fast and now I catch it sooner in real chats.",
            date: "October 8, 2025"
        )
    ]
}

#Preview {
    NavigationStack { ScenarioDetailView(state: OnboardingState()) }
        .modelContainer(AppModelContainer.previewContainer())
}

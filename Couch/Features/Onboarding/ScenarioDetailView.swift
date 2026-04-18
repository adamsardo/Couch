import SwiftData
import SwiftUI

struct ScenarioDetailView: View {
    let state: OnboardingState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.zoomNamespace) private var zoomNamespace
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
        .ignoresSafeArea(edges: .top)
        .modifier(ZoomDestination(sourceID: "scenario-detail", namespace: zoomNamespace))
    }

    @ViewBuilder
    private func content(for scenario: Scenario) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                hero(for: scenario)
                    .frame(height: 420)

                detailCard(for: scenario)
                    .offset(y: -CouchTheme.Radius.sheet)
                    .padding(.bottom, -CouchTheme.Radius.sheet)
            }
        }
        .scrollIndicators(.hidden)
        .background(CouchTheme.background)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Nice to meet you") {
                state.advance(to: .notifications)
            }
            .padding(.horizontal, CouchTheme.Spacing.lg)
            .padding(.vertical, CouchTheme.Spacing.md)
            .background(CouchTheme.background.opacity(0.98))
        }
        .overlay(alignment: .topLeading) {
            FloatingBackButton { dismiss() }
                .padding(.leading, CouchTheme.Spacing.md)
                .padding(.top, CouchTheme.Spacing.sm)
        }
    }

    // MARK: - Hero

    private func hero(for scenario: Scenario) -> some View {
        ScenarioPortraitView(
            scenario: scenario,
            crop: .topFocused,
            overlays: [.bottomScrim]
        )
        .frame(maxWidth: .infinity)
        .clipped()
    }

    // MARK: - Detail card

    private func detailCard(for scenario: Scenario) -> some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            Text("Meet \(scenario.patientName)")
                .font(CouchTheme.Typography.display)
                .foregroundStyle(CouchTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.top, CouchTheme.Spacing.lg)

            SubtitlePill(
                title: scenario.title.capitalized,
                subtitle: "AI-simulated patient. Not a real person.",
                outerRadius: CouchTheme.Radius.sheet,
                outerPadding: CouchTheme.Spacing.lg
            )

            Text("\u{201C}\(scenario.summary)\u{201D}")
                .font(CouchTheme.Typography.body)
                .italic()
                .foregroundStyle(CouchTheme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Text("Notes from past reps")
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(CouchTheme.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CouchTheme.Spacing.md) {
                        ForEach(SampleReviews.all) { review in
                            reviewCard(review)
                                .frame(width: 260)
                                .scrollTransition(
                                    topLeading: .animated(.easeOut(duration: CouchMotion.small)),
                                    bottomTrailing: .animated(.easeIn(duration: CouchMotion.press)),
                                    axis: .horizontal
                                ) { view, phase in
                                    view
                                        .opacity(phase.isIdentity ? 1 : 0.75)
                                        .scaleEffect(phase.isIdentity ? 1 : 0.96)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.vertical, 2)
                }
                .scrollTargetBehavior(.viewAligned)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: CouchTheme.Radius.sheet,
                topTrailingRadius: CouchTheme.Radius.sheet,
                style: .continuous
            )
            .fill(CouchTheme.background)
        )
    }

    private func reviewCard(_ review: SampleReview) -> some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            HStack(spacing: 2) {
                ForEach(0..<review.stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.footnote)
                        .foregroundStyle(CouchTheme.primary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("\(review.stars) stars")
            Text(review.body)
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textPrimary)
                .lineLimit(6)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(review.date)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .padding(CouchTheme.Spacing.md)
        .background(
            RoundedRectangle(
                cornerRadius: CouchTheme.Radius.inner(of: CouchTheme.Radius.bubble, padding: CouchTheme.Spacing.md),
                style: .continuous
            )
            .fill(CouchTheme.surfaceMuted)
        )
        .accessibilityElement(children: .combine)
    }
}

/// Apply a zoom navigation transition when a namespace is available.
private struct ZoomDestination: ViewModifier {
    let sourceID: String
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let namespace {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
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
        ),
        SampleReview(
            stars: 5,
            body: "Example user feedback: I was anxious before but the debrief gave me three concrete things to try in placement the next day.",
            date: "October 22, 2025"
        )
    ]
}

#Preview {
    NavigationStack { ScenarioDetailView(state: OnboardingState()) }
        .modelContainer(AppModelContainer.previewContainer())
}

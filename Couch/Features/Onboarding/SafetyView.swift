import SwiftUI

struct SafetyView: View {
    @Bindable var state: OnboardingState

    private let bullets: [(String, String)] = [
        ("checkmark.shield.fill", "This is a simulation. The patients are AI."),
        ("heart.text.clipboard.fill", "This is not therapy or crisis support."),
        ("books.vertical.fill", "It's a safe space to practise and reflect.")
    ]

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Text("Before we start")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("Quick context so you can use Couch with confidence.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: CouchTheme.Spacing.md) {
                ForEach(bullets, id: \.0) { bullet in
                    HStack(alignment: .top, spacing: CouchTheme.Spacing.md) {
                        Image(systemName: bullet.0)
                            .font(.title3)
                            .foregroundStyle(CouchTheme.primary)
                            .frame(width: 28)
                        Text(bullet.1)
                            .font(CouchTheme.Typography.body)
                            .foregroundStyle(CouchTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                }
            }
            .couchGlassCard()

            Spacer()

            PrimaryButton(title: "Got it") {
                state.advance(to: .quickProfile)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .navigationTitle("Safety")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SafetyView(state: OnboardingState()) }
}

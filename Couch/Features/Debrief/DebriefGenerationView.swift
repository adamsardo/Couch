import SwiftUI

struct DebriefGenerationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let phases: [PersonalisingLoader.Phase] = [
        .init(label: "Reading what happened in the room", duration: 1.2),
        .init(label: "Tagging the moves that landed", duration: 1.2),
        .init(label: "Shaping your next-rep drill", duration: 1.4)
    ]

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(CouchTheme.lavenderSoft.opacity(0.42))
                    .frame(width: 160, height: 160)
                Image("mascot-compact")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 122, height: 122)
                    .symbolEffect(
                        .pulse.byLayer,
                        options: .repeating.speed(0.5),
                        isActive: !reduceMotion
                    )
                    .accessibilityHidden(true)
            }
            .accessibilityLabel("Generating your debrief")

            VStack(spacing: CouchTheme.Spacing.xs + 2) {
                Text("Reading your rep...")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("Looking for what landed, what to sharpen, and one next drill.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CouchTheme.Spacing.lg)
            }

            PersonalisingLoader(phases: phases, repeats: true, onFinished: {})
                .padding(.horizontal, CouchTheme.Spacing.lg)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.background)
        .preferredColorScheme(.light)
    }
}

#Preview { DebriefGenerationView() }

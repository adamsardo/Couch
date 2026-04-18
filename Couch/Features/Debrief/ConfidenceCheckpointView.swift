import SwiftUI

struct ConfidenceCheckpointView: View {
    @Bindable var coordinator: DebriefCoordinator

    private let options: [(Int, String)] = [
        (1, "Still nervous"),
        (2, "A little steadier"),
        (3, "Noticeably more ready"),
        (4, "I'd take a real session today"),
        (5, "Bring it on")
    ]

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Label("Quick checkpoint", systemImage: "gauge.with.dots.needle.bottom.50percent")
                    .font(CouchTheme.Typography.cardTitle)
                    .foregroundStyle(CouchTheme.primary)
                Text("How ready do you feel after that rep?")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: CouchTheme.Spacing.sm) {
                ForEach(options, id: \.0) { option in
                    Button {
                        CouchHaptics.tap()
                        coordinator.setConfidence(option.0)
                    } label: {
                        HStack {
                            Image(systemName: coordinator.confidenceAfter == option.0 ? "circle.inset.filled" : "circle")
                                .foregroundStyle(coordinator.confidenceAfter == option.0 ? CouchTheme.primary : CouchTheme.textMuted)
                                .contentTransition(.symbolEffect(.replace))
                                .accessibilityHidden(true)
                            Text(option.1)
                                .foregroundStyle(CouchTheme.textPrimary)
                                .font(CouchTheme.Typography.body)
                            Spacer()
                            Text("\(option.0)")
                                .font(CouchTheme.Typography.caption.monospacedDigit())
                                .foregroundStyle(CouchTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .couchGlassCard(tint: coordinator.confidenceAfter == option.0 ? CouchTheme.primary.opacity(0.1) : nil)
                    }
                    .buttonStyle(.couchPress)
                    .accessibilityLabel(option.1)
                    .accessibilityAddTraits(coordinator.confidenceAfter == option.0 ? [.isSelected, .isButton] : .isButton)
                }
            }

            PrimaryButton(title: "See completion", systemImage: "checkmark") {
                coordinator.advance()
            }
            .disabled(coordinator.confidenceAfter == nil)
            .opacity(coordinator.confidenceAfter == nil ? 0.5 : 1)
        }
        .frame(maxWidth: .infinity)
        .couchGlassCard()
    }
}

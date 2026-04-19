import SwiftUI

/// Pill-style segmented control. Used for time-window filters (7d / 30d /
/// all-time) on History and anywhere we want a compact multi-option chip.
struct ChipSegment<Option: Hashable>: View {
    struct Item: Identifiable {
        let id: Option
        let label: String
    }

    let options: [Item]
    @Binding var selection: Option
    var tint: Color = CouchTheme.primary

    var body: some View {
        HStack(spacing: CouchTheme.Spacing.xs) {
            ForEach(options) { option in
                Button {
                    CouchHaptics.tap()
                    withAnimation(CouchMotion.pressFeedback) {
                        selection = option.id
                    }
                } label: {
                    Text(option.label)
                        .font(CouchTheme.Typography.pill)
                        .foregroundStyle(selection == option.id ? .white : CouchTheme.textPrimary)
                        .padding(.horizontal, CouchTheme.Spacing.md)
                        .padding(.vertical, CouchTheme.Spacing.xs + 2)
                        .background(
                            Capsule()
                                .fill(selection == option.id ? tint : CouchTheme.surfaceMuted)
                        )
                }
                .buttonStyle(.couchPress)
                .accessibilityAddTraits(selection == option.id ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(CouchTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(CouchTheme.surface)
                .couchElevation(.sm)
        )
    }
}

#Preview {
    struct Demo: View {
        @State private var selection: String = "7d"
        var body: some View {
            ChipSegment(
                options: [
                    .init(id: "7d", label: "7 days"),
                    .init(id: "30d", label: "30 days"),
                    .init(id: "all", label: "All time")
                ],
                selection: $selection
            )
        }
    }
    return Demo()
        .padding()
        .background(CouchTheme.background)
}

import SwiftUI

struct QuickProfileView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                Text("Help us tailor your first rep.")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("Two quick taps. Skip if you'd rather just dive in.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: CouchTheme.Spacing.md) {
                pickerCard(title: "Year level") {
                    chipRow(YearLevel.allCases, selection: $state.yearLevel)
                }
                pickerCard(title: "Placement is…") {
                    chipRow(PlacementWindow.allCases, selection: $state.placementWindow)
                }
            }

            Spacer()

            VStack(spacing: CouchTheme.Spacing.sm) {
                PrimaryButton(title: "Continue") {
                    state.advance(to: .friction)
                }
                Button("Skip for now") {
                    state.skipQuickProfile()
                }
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.primaryStrong)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .navigationTitle("About you")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func pickerCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Text(title)
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.textPrimary)
            content()
        }
        .couchGlassCard()
    }

    @ViewBuilder
    private func chipRow<T: Hashable & Identifiable & RawRepresentable>(
        _ options: [T],
        selection: Binding<T?>
    ) -> some View where T.RawValue == String {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                ChipButton(
                    label: option.rawValue,
                    isSelected: selection.wrappedValue == option
                ) {
                    selection.wrappedValue = option
                }
            }
        }
    }
}

private struct ChipButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            CouchHaptics.tap()
            action()
        }) {
            Text(label)
                .font(CouchTheme.Typography.pill)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? CouchTheme.surface : CouchTheme.textPrimary)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(CouchTheme.primary) : AnyShapeStyle(CouchTheme.surface))
                )
                .overlay(
                    Capsule().strokeBorder(CouchTheme.divider, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// Lightweight wrap layout for chip rows.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0, height: CGFloat = 0, lineHeight: CGFloat = 0, x: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                width = max(width, x - spacing)
                height += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        width = max(width, x - spacing)
        height += lineHeight
        return CGSize(width: max(0, width), height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack { QuickProfileView(state: OnboardingState()) }
}

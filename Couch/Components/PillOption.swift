import SwiftUI

/// Full-width pill option used on the multi-select and single-select question screens.
struct PillOption: View {
    let label: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button {
            CouchHaptics.tap()
            action()
        } label: {
            Text(label)
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: CouchTheme.Radius.option, style: .continuous)
                        .fill(isSelected ? CouchTheme.background : CouchTheme.surfaceMuted)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CouchTheme.Radius.option, style: .continuous)
                        .strokeBorder(
                            isSelected ? CouchTheme.textPrimary : Color.clear,
                            lineWidth: isSelected ? 1.5 : 0
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview {
    VStack(spacing: 10) {
        PillOption(label: "Constant worry", isSelected: false, action: {})
        PillOption(label: "Racing thoughts", isSelected: true, action: {})
        PillOption(label: "Panic symptoms", isSelected: false, action: {})
    }
    .padding()
    .background(CouchTheme.background)
}

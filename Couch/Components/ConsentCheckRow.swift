import SwiftUI

/// Consent row with an orange check bullet and rich-text body. Used on the privacy screen.
struct ConsentCheckRow: View {
    let text: LocalizedStringKey
    var isChecked: Bool
    var action: () -> Void

    var body: some View {
        Button {
            CouchHaptics.tap()
            action()
        } label: {
            HStack(alignment: .top, spacing: CouchTheme.Spacing.md) {
                Image(systemName: isChecked ? "circle.inset.filled" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? CouchTheme.primary : CouchTheme.textMuted)
                Text(text)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textPrimary)
                    .tint(CouchTheme.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.couchPress)
        .accessibilityAddTraits(isChecked ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview {
    VStack(spacing: 14) {
        ConsentCheckRow(
            text: "I understand and agree that Couch is not therapy, not medical care, and not a crisis service.",
            isChecked: true,
            action: {}
        )
        ConsentCheckRow(
            text: "I agree to processing of my personal data for providing me Couch app functions. See more in [Privacy Policy](https://example.com).",
            isChecked: false,
            action: {}
        )
    }
    .padding()
    .background(CouchTheme.background)
}

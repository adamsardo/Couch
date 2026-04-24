import SwiftUI

struct FreezeHelpSheet: View {
    var onPaste: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let prompts: [(String, String)] = [
        ("Reflect content", "It sounds like work has been wearing you down lately."),
        ("Ask about life around them", "How's Jess been with all of this going on?"),
        ("Normalise without diagnosing", "Plenty of people find sitting in this room unfamiliar at first.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: CouchTheme.Spacing.xs) {
                    Capsule()
                        .fill(CouchTheme.textMuted.opacity(0.28))
                        .frame(width: 44, height: 5)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, CouchTheme.Spacing.xs)
                    Text("Stuck for a moment?")
                        .font(CouchTheme.Typography.title)
                        .foregroundStyle(CouchTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Pick one to drop into your text box. You decide whether to send.")
                        .font(CouchTheme.Typography.body)
                        .foregroundStyle(CouchTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(prompts, id: \.0) { entry in
                    Button {
                        CouchHaptics.tap()
                        onPaste(entry.1)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.0)
                                .font(CouchTheme.Typography.cardTitle)
                                .foregroundStyle(CouchTheme.primaryStrong)
                            Text(entry.1)
                                .font(CouchTheme.Typography.body)
                                .foregroundStyle(CouchTheme.textPrimary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .minimumScaleFactor(0.88)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .couchGlassCard()
                    }
                    .buttonStyle(.couchPress)
                }
            }
            .padding(CouchTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CouchTheme.background)
        .preferredColorScheme(.light)
        .presentationBackground(CouchTheme.background)
    }
}

#Preview {
    FreezeHelpSheet(onPaste: { _ in })
}

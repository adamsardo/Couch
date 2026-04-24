import SwiftUI

/// 2-column grid of student-first practice promises shown on the onboarding
/// proof screen. If an asset is missing, the text chip still carries the idea.
struct SocialProofGrid: View {
    struct ProofItem: Identifiable, Equatable {
        let id = UUID()
        let displayName: String
        let assetName: String
    }

    var caption: String = "Built for placement-bound students who need reps, not another lecture"
    var items: [ProofItem] = SocialProofGrid.practiceSteps
    /// Colour of the caption.
    var captionColor: Color = CouchTheme.textMuted
    /// Colour used for the placeholder label/icon when a real logo asset
    /// is missing. Overridable so we can render on dark / brand-colour surfaces.
    var placeholderColor: Color = CouchTheme.textSecondary

    static let practiceSteps: [ProofItem] = [
        ProofItem(displayName: "Open the app", assetName: "proof-open"),
        ProofItem(displayName: "Meet a virtual patient", assetName: "proof-patient"),
        ProofItem(displayName: "Practise the hard part", assetName: "proof-practice"),
        ProofItem(displayName: "Debrief calmly", assetName: "proof-debrief"),
        ProofItem(displayName: "Repeat the skill", assetName: "proof-repeat"),
        ProofItem(displayName: "Show up steadier", assetName: "proof-confidence")
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Text(caption)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(captionColor)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: CouchTheme.Spacing.lg) {
                ForEach(items) { item in
                    ProofTile(item: item, placeholderColor: placeholderColor)
                }
            }
        }
    }
}

private struct ProofTile: View {
    let item: SocialProofGrid.ProofItem
    var placeholderColor: Color

    var body: some View {
        Group {
            if UIImage(named: item.assetName) != nil {
                Image(item.assetName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
            } else {
                placeholder
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(item.displayName)
    }

    private var placeholder: some View {
        HStack(spacing: 8) {
            Image(systemName: CouchIcons.sparkles)
                .foregroundStyle(placeholderColor)
                .accessibilityHidden(true)
            Text(item.displayName)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(placeholderColor)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    SocialProofGrid()
        .padding()
        .background(CouchTheme.background)
}

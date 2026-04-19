import SwiftUI

/// 2-column grid of university logos shown on the social-proof marketing screen.
/// Image assets live in `Assets.xcassets` under each entry's `assetName`.
struct SocialProofGrid: View {
    struct University: Identifiable, Equatable {
        let id = UUID()
        let displayName: String
        let assetName: String
    }

    var caption: String = "Our method draws on evidence from"
    var universities: [University] = SocialProofGrid.go8
    /// Colour of the "Our method draws on evidence from" caption.
    var captionColor: Color = CouchTheme.textMuted
    /// Colour used for the placeholder label/icon when a real logo asset
    /// is missing. Overridable so we can render on dark / blue surfaces.
    var placeholderColor: Color = CouchTheme.textSecondary

    /// Australian Group of Eight research-intensive universities, chosen for their
    /// strong psychology and clinical-training programs.
    static let go8: [University] = [
        University(displayName: "University of Melbourne", assetName: "uni-melbourne"),
        University(displayName: "University of Sydney", assetName: "uni-sydney"),
        University(displayName: "UNSW Sydney", assetName: "uni-unsw"),
        University(displayName: "Monash University", assetName: "uni-monash"),
        University(displayName: "University of Queensland", assetName: "uni-uq"),
        University(displayName: "Australian National University", assetName: "uni-anu")
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Text(caption)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(captionColor)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: CouchTheme.Spacing.lg) {
                ForEach(universities) { uni in
                    LogoTile(university: uni, placeholderColor: placeholderColor)
                }
            }
        }
    }
}

private struct LogoTile: View {
    let university: SocialProofGrid.University
    var placeholderColor: Color

    var body: some View {
        Group {
            if UIImage(named: university.assetName) != nil {
                Image(university.assetName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
            } else {
                placeholder
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(university.displayName)
    }

    private var placeholder: some View {
        HStack(spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(placeholderColor)
                .accessibilityHidden(true)
            Text(university.displayName)
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

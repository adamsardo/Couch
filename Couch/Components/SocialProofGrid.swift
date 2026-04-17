import SwiftUI

/// 2-column grid of university logos shown on the social-proof marketing screen.
/// Image assets live in `Assets.xcassets` under the names in `logoAssetNames`.
struct SocialProofGrid: View {
    var caption: String = "Our method based on best works from"
    var logoAssetNames: [String] = [
        "uni-stanford",
        "uni-boston",
        "uni-humboldt",
        "uni-michiganstate",
        "uni-harvard",
        "uni-nationallouis"
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Text(caption)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.textMuted)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: CouchTheme.Spacing.lg) {
                ForEach(logoAssetNames, id: \.self) { name in
                    LogoTile(assetName: name)
                }
            }
        }
    }
}

private struct LogoTile: View {
    let assetName: String

    var body: some View {
        Group {
            if UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
            } else {
                placeholder
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
    }

    private var placeholder: some View {
        HStack(spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(CouchTheme.textSecondary)
            Text(humanized)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var humanized: String {
        assetName
            .replacingOccurrences(of: "uni-", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

#Preview {
    SocialProofGrid()
        .padding()
        .background(CouchTheme.background)
}

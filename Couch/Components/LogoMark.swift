import SwiftUI

/// Couch mark. The compact mark uses the supplied icon asset directly. Until
/// a production wordmark file is supplied, the wordmark is rendered as text
/// instead of a cropped board asset.
struct LogoMark: View {
    enum Style: Equatable {
        /// Full wordmark asset.
        case pill
        /// Compact mascot icon.
        case mark
    }

    var style: Style = .pill
    var height: CGFloat = 120
    var tint: Color = .white
    var accent: Color = CouchTheme.primary

    var body: some View {
        switch style {
        case .pill:
            pillBody
        case .mark:
            markBody
        }
    }

    private var pillBody: some View {
        Text("couch")
            .font(.system(size: height, weight: .bold, design: .rounded))
            .foregroundStyle(CouchTheme.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityLabel("Couch")
    }

    private var markBody: some View {
        Image("mascot-compact")
            .resizable()
            .scaledToFit()
            .frame(width: height, height: height)
            .accessibilityLabel("Couch")
    }
}

#Preview("Pill") {
    LogoMark(style: .pill, height: 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.heroBackground)
}

#Preview("Mark") {
    LogoMark(style: .mark, height: 40)
        .padding()
        .background(CouchTheme.background)
}

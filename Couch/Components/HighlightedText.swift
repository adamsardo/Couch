import SwiftUI

/// Renders a single display headline with one phrase colored in the brand orange.
/// Splits on the first case-insensitive occurrence; falls back to plain text if missing.
struct HighlightedText: View {
    let fullText: String
    let highlight: String
    var font: Font = CouchTheme.Typography.display
    /// Defaults to the legible yellow-shifted brand colour so the highlight
    /// reads crisply on white body surfaces. Pass `CouchTheme.accent`
    /// explicitly for the bright yellow used on blue hero screens.
    var highlightColor: Color = CouchTheme.accentOnLight
    var baseColor: Color = CouchTheme.textPrimary

    var body: some View {
        composed
            .font(font)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var composed: Text {
        guard let range = fullText.range(of: highlight, options: .caseInsensitive) else {
            return Text(fullText).foregroundStyle(baseColor)
        }
        let prefix = Text(verbatim: String(fullText[..<range.lowerBound])).foregroundStyle(baseColor)
        let match = Text(verbatim: String(fullText[range])).foregroundStyle(highlightColor)
        let suffix = Text(verbatim: String(fullText[range.upperBound...])).foregroundStyle(baseColor)
        return Text("\(prefix)\(match)\(suffix)")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        HighlightedText(
            fullText: "Our science-backed practice reps help 9,000+ students show up calm.",
            highlight: "show up calm"
        )
        HighlightedText(
            fullText: "Your wellbeing. Your privacy.",
            highlight: "wellbeing"
        )
        HighlightedText(
            fullText: "Build confidence is easier with short Couch reps.",
            highlight: "Build confidence"
        )
    }
    .padding()
    .background(CouchTheme.background)
}

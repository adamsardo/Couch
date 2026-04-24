import SwiftUI

/// Renders a single display headline with one phrase colored in the brand accent.
/// Splits on the first case-insensitive occurrence; falls back to plain text if missing.
struct HighlightedText: View {
    let fullText: String
    let highlight: String
    var font: Font = CouchTheme.Typography.display
    /// Defaults to the deep-violet accent so highlighted words read crisply
    /// on cream and white body surfaces.
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
            fullText: "Low stakes reps for high stakes conversations.",
            highlight: "Low stakes reps"
        )
        HighlightedText(
            fullText: "Practice, not therapy. Private by default.",
            highlight: "Private"
        )
        HighlightedText(
            fullText: "Build confidence is easier with short Couch reps.",
            highlight: "Build confidence"
        )
    }
    .padding()
    .background(CouchTheme.background)
}

import SwiftUI

/// Generic 1-up stat block: big numeric (monospaced), caption below. Use
/// inside `HStack`/`LazyVGrid` to build 2- or 3-up stat rows on Progress
/// rows, debrief scorecards, and session intro.
struct StatTile: View {
    var value: String
    var caption: String
    var trend: Trend? = nil
    var valueFont: Font = .system(.title2, design: .rounded, weight: .bold).monospacedDigit()
    var captionColor: Color = CouchTheme.textMuted
    var valueColor: Color = CouchTheme.textPrimary
    var background: Color = CouchTheme.surfaceMuted
    var tintBackground: Bool = true

    enum Trend: Equatable {
        case up
        case down
        case neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return CouchTheme.success
            case .down: return CouchTheme.warning
            case .neutral: return CouchTheme.textMuted
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: CouchTheme.Spacing.xs) {
                Text(value)
                    .font(valueFont)
                    .foregroundStyle(valueColor)
                    .contentTransition(.numericText())
                if let trend {
                    Image(systemName: trend.icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(trend.color)
                        .accessibilityHidden(true)
                }
            }
            Text(caption)
                .font(CouchTheme.Typography.caption.weight(.semibold))
                .foregroundStyle(captionColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CouchTheme.Spacing.md)
        .background(
            RoundedRectangle(
                cornerRadius: CouchTheme.Radius.bubble,
                style: .continuous
            )
            .fill(tintBackground ? background : Color.clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption): \(value)")
    }
}

#Preview {
    HStack {
        StatTile(value: "3", caption: "Reps this week", trend: .up)
        StatTile(value: "7", caption: "Day streak")
        StatTile(value: "3.6", caption: "Avg confidence", trend: .up)
    }
    .padding()
    .background(CouchTheme.background)
}

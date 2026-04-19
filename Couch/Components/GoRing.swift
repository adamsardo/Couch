import SwiftUI

/// Circular stat ring with a track, a filled arc, a big numeric in the
/// centre, and a caption underneath. Used in the Home dashboard as a trio
/// (reps · streak · confidence). Fills animate from 0 on appear so the
/// dashboard reads as "alive".
struct GoRing: View {
    var value: Double
    var max: Double
    var label: String
    var caption: String
    var trackColor: Color = CouchTheme.surfaceMuted
    var fillColor: Color = CouchTheme.primary
    var valueColor: Color = CouchTheme.textPrimary
    var captionColor: Color = CouchTheme.textMuted
    var size: CGFloat = 96
    var lineWidth: CGFloat = 10
    /// When true the centre shows an integer-formatted value (no decimals).
    /// Set false for fractional values like confidence.
    var integerValue: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var clampedProgress: Double {
        guard max > 0 else { return 0 }
        return Swift.max(0, Swift.min(value / max, 1.0))
    }

    private var animatedProgress: Double {
        appeared || reduceMotion ? clampedProgress : 0
    }

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(trackColor, lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        fillColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.8),
                        value: animatedProgress
                    )

                VStack(spacing: 0) {
                    Text(valueText)
                        .font(.system(size: size * 0.28, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(valueColor)
                        .contentTransition(.numericText())
                    Text(label)
                        .font(CouchTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(captionColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 4)
                }
            }
            .frame(width: size, height: size)
            Text(caption)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(captionColor)
                .lineLimit(1)
        }
        .task { appeared = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(valueText). \(caption).")
    }

    private var valueText: String {
        if integerValue {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

#Preview {
    HStack(spacing: 16) {
        GoRing(value: 2, max: 3, label: "Reps", caption: "this week")
        GoRing(value: 5, max: 7, label: "Streak", caption: "days", fillColor: CouchTheme.accentOnLight)
        GoRing(
            value: 3.6,
            max: 5,
            label: "Confidence",
            caption: "avg / 5",
            fillColor: CouchTheme.success,
            integerValue: false
        )
    }
    .padding()
    .background(CouchTheme.background)
}

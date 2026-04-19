import SwiftUI

/// Lightweight line chart for a 1–5 confidence series. Pure SwiftUI `Path`
/// work — no dependency on `Charts` or extra assets. The last point is
/// emphasised with a larger dot + value badge.
struct ConfidenceTrendChart: View {
    /// Ordered series: leading point is the oldest, trailing point is the
    /// most recent. Values are clamped to 0–5 for display.
    let values: [Double]
    var lineColor: Color = CouchTheme.primary
    var fillColor: Color = CouchTheme.primary.opacity(0.12)
    var height: CGFloat = 140

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let clamped = values.map { max(0, min($0, 5)) }

            ZStack {
                gridlines(size: size)

                if clamped.count >= 2 {
                    trendFill(size: size, values: clamped)
                    trendLine(size: size, values: clamped)
                    endDot(size: size, values: clamped)
                    endBadge(size: size, values: clamped)
                } else {
                    emptyState
                }
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
    }

    private func gridlines(size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                Divider().overlay(CouchTheme.divider.opacity(0.6))
                Spacer()
            }
            Divider().overlay(CouchTheme.divider.opacity(0.6))
        }
        .frame(width: size.width, height: size.height)
    }

    private func trendFill(size: CGSize, values: [Double]) -> some View {
        Path { path in
            let points = pointPath(size: size, values: values)
            guard let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: first.x, y: size.height))
            path.addLine(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.addLine(to: CGPoint(x: last.x, y: size.height))
            path.closeSubpath()
        }
        .fill(fillColor)
    }

    private func trendLine(size: CGSize, values: [Double]) -> some View {
        Path { path in
            let points = pointPath(size: size, values: values)
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(lineColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    private func endDot(size: CGSize, values: [Double]) -> some View {
        let points = pointPath(size: size, values: values)
        return Group {
            if let last = points.last {
                Circle()
                    .fill(lineColor)
                    .frame(width: 12, height: 12)
                    .position(x: last.x, y: last.y)
                    .overlay(
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                            .frame(width: 12, height: 12)
                            .position(x: last.x, y: last.y)
                    )
            }
        }
    }

    private func endBadge(size: CGSize, values: [Double]) -> some View {
        let points = pointPath(size: size, values: values)
        return Group {
            if let last = points.last, let lastValue = values.last {
                Text(String(format: "%.1f", lastValue))
                    .font(CouchTheme.Typography.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(lineColor))
                    .position(
                        x: min(size.width - 22, last.x + 22),
                        y: max(12, last.y - 14)
                    )
            }
        }
    }

    private func pointPath(size: CGSize, values: [Double]) -> [CGPoint] {
        let count = Swift.max(values.count, 1)
        let stepX = count > 1 ? size.width / CGFloat(count - 1) : 0
        return values.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            let normalised = value / 5.0
            let y = size.height - CGFloat(normalised) * size.height
            return CGPoint(x: x, y: y)
        }
    }

    private var emptyState: some View {
        Text("Complete another rep to see your trend")
            .font(CouchTheme.Typography.caption)
            .foregroundStyle(CouchTheme.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var accessibilityLabel: String {
        guard let last = values.last else { return "No confidence data" }
        return "Latest confidence \(String(format: "%.1f", last)) out of 5, trend over \(values.count) reps"
    }
}

#Preview {
    VStack(spacing: 24) {
        ConfidenceTrendChart(values: [2.0, 2.4, 3.1, 3.0, 3.6, 4.1])
            .padding()
            .background(CouchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: CouchTheme.Radius.card))

        ConfidenceTrendChart(values: [3.2])
            .padding()
            .background(CouchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: CouchTheme.Radius.card))
    }
    .padding()
    .background(CouchTheme.background)
}

import Charts
import SwiftUI

/// Marketing chart comparing a regular-practice curve to a trial-and-error curve,
/// with two annotation pills matching the LovOn self-growth screenshot.
struct SciencePathChart: View {
    private struct Point: Identifiable {
        let id = UUID()
        let series: String
        let x: Double
        let y: Double
    }

    private let orangePoints: [Point] = [
        Point(series: "With Couch", x: 0, y: 0.2),
        Point(series: "With Couch", x: 0.35, y: 0.28),
        Point(series: "With Couch", x: 0.65, y: 0.5),
        Point(series: "With Couch", x: 0.85, y: 0.75),
        Point(series: "With Couch", x: 1.0, y: 0.95)
    ]

    private let grayPoints: [Point] = [
        Point(series: "Trial and error", x: 0, y: 0.2),
        Point(series: "Trial and error", x: 0.4, y: 0.22),
        Point(series: "Trial and error", x: 0.7, y: 0.2),
        Point(series: "Trial and error", x: 1.0, y: 0.15)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
            Text("Confidence")
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(CouchTheme.textSecondary)
                .rotationEffect(.degrees(-90), anchor: .bottomLeading)
                .fixedSize()
                .frame(width: 0, alignment: .leading)
                .padding(.leading, 6)

            ZStack(alignment: .topTrailing) {
                chart
                    .frame(height: 220)

                AnnotationPill(
                    title: "Do 1+ rep a week",
                    color: CouchTheme.primary,
                    textColor: .white
                )
                .offset(x: -110, y: 24)

                AnnotationPill(
                    title: "Do it by trial and error",
                    color: CouchTheme.textPrimary,
                    textColor: .white
                )
                .offset(x: -90, y: 110)
            }

            HStack {
                Text("Now")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textSecondary)
                Spacer()
                Text("in 3 months")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(grayPoints) { p in
                LineMark(x: .value("t", p.x), y: .value("y", p.y))
                    .foregroundStyle(CouchTheme.textMuted)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3))
            }
            if let last = grayPoints.last {
                PointMark(x: .value("t", last.x), y: .value("y", last.y))
                    .foregroundStyle(CouchTheme.textPrimary)
                    .symbolSize(90)
                    .annotation(position: .trailing, alignment: .leading, spacing: 4) {
                        Text("Stuck")
                            .font(CouchTheme.Typography.caption)
                            .foregroundStyle(CouchTheme.textSecondary)
                    }
            }

            ForEach(orangePoints) { p in
                LineMark(x: .value("t", p.x), y: .value("y", p.y))
                    .foregroundStyle(CouchTheme.primary)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 4))
            }
            if let last = orangePoints.last {
                PointMark(x: .value("t", last.x), y: .value("y", last.y))
                    .foregroundStyle(CouchTheme.primary)
                    .symbolSize(120)
                    .annotation(position: .topTrailing, alignment: .leading, spacing: 4) {
                        Text("Calm under pressure")
                            .font(CouchTheme.Typography.caption.weight(.semibold))
                            .foregroundStyle(CouchTheme.primary)
                    }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...1.05)
        .chartXScale(domain: -0.05...1.2)
    }
}

private struct AnnotationPill: View {
    let title: String
    let color: Color
    let textColor: Color

    var body: some View {
        Text(title)
            .font(CouchTheme.Typography.pill)
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(color))
            .shadow(color: CouchTheme.textPrimary.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    SciencePathChart()
        .padding()
        .background(CouchTheme.background)
}

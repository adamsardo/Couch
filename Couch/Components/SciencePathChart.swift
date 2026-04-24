import SwiftUI

/// Marketing chart showing two trajectories over three months:
/// - Brand: regular short reps → "Calm under pressure"
/// - Muted: trial-and-error → "Stuck"
///
/// Drawn with two custom `Path`s over a normalized coordinate system so
/// annotation pills, end dots, and labels all align with the curves regardless
/// of the host width.
struct SciencePathChart: View {
    enum Appearance {
        /// Default on-white presentation: violet brand curve, gray muted curve.
        case light
        /// On-hero presentation for the violet full-bleed marketing screen:
        /// white brand curve with a peach end-dot, translucent-white muted
        /// curve, and white/peach annotation pills.
        case onHero
    }

    var appearance: Appearance = .light
    private let samples = 60

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            yAxisLabel
            VStack(spacing: 8) {
                plotArea
                    .frame(height: 220)
                xAxisLabels
            }
        }
    }

    // MARK: - Y axis

    private var yAxisLabel: some View {
        Text("Confidence")
            .font(CouchTheme.Typography.caption)
            .foregroundStyle(axisLabelColor)
            .rotationEffect(.degrees(-90))
            .fixedSize()
            .frame(width: 14)
    }

    // MARK: - Plot

    private var plotArea: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // End dot sits at 70% of the width; the remaining 30% is label room.
            let dotX: Double = 0.70

            ZStack {
                dashedEndLine(in: size, at: dotX)

                Path { path in
                    appendCurve(to: &path, in: size, xEnd: dotX, curve: grayCurve)
                }
                .stroke(
                    mutedCurveColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )

                Path { path in
                    appendCurve(to: &path, in: size, xEnd: dotX, curve: brandCurve)
                }
                .stroke(
                    brandCurveColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )

                endDot(
                    color: mutedEndDotColor,
                    diameter: 10,
                    in: size,
                    at: CGPoint(x: dotX, y: 1 - grayCurve(dotX))
                )
                endDot(
                    color: brandEndDotColor,
                    diameter: 13,
                    in: size,
                    at: CGPoint(x: dotX, y: 1 - brandCurve(dotX))
                )

                endLabel(
                    text: "Stuck",
                    color: mutedEndLabelColor,
                    in: size,
                    at: CGPoint(x: dotX + 0.03, y: 1 - grayCurve(dotX)),
                    maxWidth: size.width * 0.26
                )

                endLabel(
                    text: "Calm under\npressure",
                    color: brandEndLabelColor,
                    weight: .semibold,
                    in: size,
                    at: CGPoint(x: dotX + 0.03, y: 1 - brandCurve(dotX)),
                    maxWidth: size.width * 0.26
                )

                AnnotationPill(
                    title: "Do 1+ rep a week",
                    color: brandPillFill,
                    textColor: brandPillText
                )
                .pinned(to: CGPoint(x: 0.33, y: 0.42), in: size)

                AnnotationPill(
                    title: "Do it by trial and error",
                    color: mutedPillFill,
                    textColor: mutedPillText
                )
                .pinned(to: CGPoint(x: 0.40, y: 0.72), in: size)
            }
        }
    }

    // MARK: - X axis

    private var xAxisLabels: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                Text("Now")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(axisLabelColor)
                    .fixedSize()
                    .position(x: 18, y: 8)

                Text("in 3 months")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(axisLabelColor)
                    .fixedSize()
                    .position(x: width * 0.70, y: 8)
            }
        }
        .frame(height: 16)
    }

    // MARK: - Curves (height on 0...1, 0 = bottom, 1 = top)

    /// Regular-practice trajectory: gentle start, exponential rise near the end.
    private func brandCurve(_ x: Double) -> Double {
        let t = max(0, min(1, x / 0.70)) // normalise over the visible plot width
        return 0.30 + 0.62 * pow(t, 2.4)
    }

    /// Trial-and-error trajectory: flat, gently declining.
    private func grayCurve(_ x: Double) -> Double {
        let t = max(0, min(1, x / 0.70))
        return 0.30 - 0.14 * t
    }

    // MARK: - Appearance-driven colours

    private var axisLabelColor: Color {
        switch appearance {
        case .light: return CouchTheme.textSecondary
        case .onHero: return .white.opacity(0.7)
        }
    }

    private var brandCurveColor: Color {
        switch appearance {
        case .light: return CouchTheme.primary
        case .onHero: return .white
        }
    }

    private var mutedCurveColor: Color {
        switch appearance {
        case .light: return CouchTheme.textMuted.opacity(0.55)
        case .onHero: return .white.opacity(0.35)
        }
    }

    private var brandEndDotColor: Color {
        switch appearance {
        case .light: return CouchTheme.primary
        case .onHero: return CouchTheme.accent
        }
    }

    private var mutedEndDotColor: Color {
        switch appearance {
        case .light: return CouchTheme.textPrimary
        case .onHero: return .white.opacity(0.75)
        }
    }

    private var brandEndLabelColor: Color {
        switch appearance {
        case .light: return CouchTheme.primary
        case .onHero: return CouchTheme.accent
        }
    }

    private var mutedEndLabelColor: Color {
        switch appearance {
        case .light: return CouchTheme.textSecondary
        case .onHero: return .white.opacity(0.7)
        }
    }

    private var brandPillFill: Color {
        switch appearance {
        case .light: return CouchTheme.primary
        case .onHero: return .white
        }
    }

    private var brandPillText: Color {
        switch appearance {
        case .light: return .white
        case .onHero: return CouchTheme.primary
        }
    }

    private var mutedPillFill: Color {
        switch appearance {
        case .light: return CouchTheme.textPrimary
        case .onHero: return CouchTheme.ink.opacity(0.72)
        }
    }

    private var mutedPillText: Color {
        switch appearance {
        case .light: return .white
        case .onHero: return .white
        }
    }

    private var dashColor: Color {
        switch appearance {
        case .light: return CouchTheme.divider
        case .onHero: return .white.opacity(0.3)
        }
    }

    // MARK: - Drawing helpers

    private func appendCurve(
        to path: inout Path,
        in size: CGSize,
        xEnd: Double,
        curve: (Double) -> Double
    ) {
        for step in 0...samples {
            let fractionX = Double(step) / Double(samples) * xEnd
            let point = CGPoint(
                x: fractionX * size.width,
                y: (1 - curve(fractionX)) * size.height
            )
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
    }

    private func dashedEndLine(in size: CGSize, at xFraction: Double) -> some View {
        Path { path in
            let x = xFraction * size.width
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }
        .stroke(
            dashColor,
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )
    }

    private func endDot(
        color: Color,
        diameter: CGFloat,
        in size: CGSize,
        at unit: CGPoint
    ) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .position(
                x: unit.x * size.width,
                y: unit.y * size.height
            )
    }

    private func endLabel(
        text: String,
        color: Color,
        weight: Font.Weight = .semibold,
        in size: CGSize,
        at unit: CGPoint,
        maxWidth: CGFloat
    ) -> some View {
        Text(text)
            .font(CouchTheme.Typography.caption.weight(weight))
            .foregroundStyle(color)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(width: maxWidth, alignment: .leading)
            .position(
                x: unit.x * size.width + maxWidth / 2,
                y: unit.y * size.height
            )
    }
}

// MARK: - Annotation pill

private struct AnnotationPill: View {
    let title: String
    let color: Color
    let textColor: Color

    var body: some View {
        Text(title)
            .font(CouchTheme.Typography.pill)
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(color))
            .couchElevation(.sm)
            .fixedSize()
    }
}

private extension View {
    /// Position a view at a unit-space point (0...1 in both axes) inside a
    /// parent with known `size`.
    func pinned(to unit: CGPoint, in size: CGSize) -> some View {
        self.position(
            x: unit.x * size.width,
            y: unit.y * size.height
        )
    }
}

#Preview("Light") {
    SciencePathChart()
        .padding()
        .frame(height: 280)
        .background(CouchTheme.background)
}

#Preview("On hero") {
    SciencePathChart(appearance: .onHero)
        .padding()
        .frame(height: 280)
        .background(CouchTheme.heroBackground)
}

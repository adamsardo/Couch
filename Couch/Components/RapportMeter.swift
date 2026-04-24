import SwiftUI

/// Thin pill-capsule shown under the call timer. Animated bar reflects the
/// live rapport score 0–100; colour smoothly lerps from warning (low) to
/// warm accent (high) through the deep-violet midpoint.
struct RapportMeter: View {
    /// 0–100.
    var score: Int
    var reduceMotion: Bool = false

    private var clamped: Double { max(0, min(Double(score), 100)) / 100.0 }

    var body: some View {
        HStack(spacing: CouchTheme.Spacing.xs) {
            Image(systemName: "heart.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(barColor)
                .accessibilityHidden(true)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                    Capsule()
                        .fill(barColor)
                        .frame(width: proxy.size.width * clamped)
                        .animation(
                            reduceMotion ? nil : CouchMotion.stateChange,
                            value: clamped
                        )
                }
            }
            .frame(height: 6)
            .frame(width: 90)

            Text("\(Int(clamped * 100))")
                .font(CouchTheme.Typography.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, CouchTheme.Spacing.sm)
        .padding(.vertical, CouchTheme.Spacing.xs)
        .couchGlassCapsule()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rapport \(Int(clamped * 100)) of 100")
    }

    private var barColor: Color {
        if clamped < 0.35 { return CouchTheme.warning }
        if clamped > 0.8 { return CouchTheme.accent }
        return CouchTheme.primary
    }
}

#Preview {
    VStack(spacing: 16) {
        RapportMeter(score: 20)
        RapportMeter(score: 55)
        RapportMeter(score: 92)
    }
    .padding()
    .background(CouchTheme.callSurface)
}

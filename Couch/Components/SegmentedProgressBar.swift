import SwiftUI

/// Discrete, pill-segment progress rail used across onboarding. Each segment
/// is either filled (current step or earlier) or track-tinted. The active
/// segment springs in when it advances.
struct SegmentedProgressBar: View {
    var current: Int
    var total: Int
    var trackColor: Color = CouchTheme.surfaceMuted
    var fillColor: Color = CouchTheme.primary
    var spacing: CGFloat = 6
    var height: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Capsule()
                    .fill(isFilled(index) ? fillColor : trackColor)
                    .frame(height: height)
                    .animation(CouchMotion.progressFill, value: current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(min(current + 1, total)) of \(total)")
    }

    private func isFilled(_ index: Int) -> Bool {
        index <= current
    }
}

#Preview {
    VStack(spacing: 16) {
        SegmentedProgressBar(current: 0, total: 6)
        SegmentedProgressBar(current: 2, total: 6)
        SegmentedProgressBar(current: 5, total: 6)
        SegmentedProgressBar(
            current: 3,
            total: 6,
            trackColor: .white.opacity(0.25),
            fillColor: .white
        )
        .padding()
        .background(CouchTheme.heroBackground)
    }
    .padding()
    .background(CouchTheme.background)
}

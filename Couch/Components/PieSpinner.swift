import SwiftUI

/// White disc with an orange pie-wedge that rotates continuously. Used by the
/// personalising screen as a calm, non-intrusive loading indicator.
struct PieSpinner: View {
    var diameter: CGFloat = 90
    var wedgeSpan: Angle = .degrees(95)
    var rotationDuration: Double = 1.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .couchElevation(.lg, tint: CouchTheme.primary)

            PieWedge(span: wedgeSpan)
                .fill(CouchTheme.primary)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: diameter, height: diameter)
        .onAppear(perform: startSpinning)
        .accessibilityLabel("Loading")
    }

    private func startSpinning() {
        guard !reduceMotion else { return }
        withAnimation(
            .linear(duration: rotationDuration)
                .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
    }
}

private struct PieWedge: Shape {
    let span: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start: Angle = .degrees(-90)
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: start,
            endAngle: start + span,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    PieSpinner()
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white, CouchTheme.primarySoft.opacity(0.6), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}

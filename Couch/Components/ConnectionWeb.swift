import SwiftUI

/// Decorative "You" orb surrounded by orbiting topic pills connected with soft squiggles.
/// Paths and pills share a single center-aligned ZStack so the squiggles terminate on the
/// pill offsets regardless of screen size.
struct ConnectionWeb: View {
    struct Node: Identifiable {
        let id = UUID()
        let label: String
        let offset: CGSize
    }

    var nodes: [Node] = [
        Node(label: "Intakes", offset: CGSize(width: -120, height: -80)),
        Node(label: "Confidence", offset: CGSize(width: 110, height: -60)),
        Node(label: "Freeze moments", offset: CGSize(width: -130, height: 50)),
        Node(label: "Resistant patients", offset: CGSize(width: 110, height: 50)),
        Node(label: "Feedback", offset: CGSize(width: -10, height: 130))
    ]

    var body: some View {
        ZStack {
            ForEach(nodes) { node in
                ConnectionSquiggle(end: node.offset)
                    .stroke(
                        CouchTheme.textMuted.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1.2, dash: [3, 4])
                    )
            }

            ForEach(nodes) { node in
                NodePill(label: node.label)
                    .offset(node.offset)
            }

            centerYou
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
    }

    private var centerYou: some View {
        HStack(spacing: 6) {
            Text("You")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Image(systemName: "heart.fill")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(CouchTheme.accentGradient)
                .shadow(color: CouchTheme.primary.opacity(0.35), radius: 24, x: 0, y: 8)
        )
    }
}

/// A quadratic squiggle starting at the center of the container and ending at `end`
/// (which is an offset from center — matching the pill offsets in `ConnectionWeb`).
private struct ConnectionSquiggle: Shape {
    let end: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let target = CGPoint(x: center.x + end.width, y: center.y + end.height)
        let control = CGPoint(
            x: (center.x + target.x) / 2 + 20,
            y: (center.y + target.y) / 2 - 10
        )
        path.move(to: center)
        path.addQuadCurve(to: target, control: control)
        return path
    }
}

private struct NodePill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(CouchTheme.Typography.pill)
            .foregroundStyle(CouchTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(CouchTheme.surfaceMuted)
            )
    }
}

#Preview {
    ConnectionWeb()
        .padding()
        .background(CouchTheme.background)
}

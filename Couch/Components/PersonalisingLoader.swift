import SwiftUI

/// Three sequential progress bars that animate with labelled phases.
/// `onFinished` fires when the last phase completes.
struct PersonalisingLoader: View {
    struct Phase: Identifiable, Equatable {
        let id = UUID()
        let label: String
        let duration: Double
    }

    var phases: [Phase]
    var repeats: Bool
    var onFinished: () -> Void

    @State private var progress: [Double]
    @State private var activeIndex: Int = 0

    init(phases: [Phase], repeats: Bool = false, onFinished: @escaping () -> Void) {
        self.phases = phases
        self.repeats = repeats
        self.onFinished = onFinished
        _progress = State(initialValue: Array(repeating: 0.0, count: phases.count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
            ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                VStack(alignment: .leading, spacing: 8) {
                    Text(phase.label)
                        .font(CouchTheme.Typography.cardTitle)
                        .foregroundStyle(index <= activeIndex ? CouchTheme.textPrimary : CouchTheme.textMuted)
                    OnboardingProgressBar(progress: progress[index])
                        .padding(.vertical, 6)
                        .padding(.horizontal, CouchTheme.Spacing.md)
                        .background(
                            RoundedRectangle(
                                cornerRadius: CouchTheme.Radius.inner(of: CouchTheme.Radius.bubble, padding: 4),
                                style: .continuous
                            )
                            .fill(CouchTheme.background)
                            .couchElevation(.sm)
                        )
                }
            }
        }
        .task { await run() }
    }

    private func run() async {
        repeat {
            progress = Array(repeating: 0.0, count: phases.count)
            for (index, phase) in phases.enumerated() {
                guard !Task.isCancelled else { return }
                activeIndex = index
                let steps = 40
                let stepDuration: Duration = .seconds(phase.duration / Double(steps))
                for step in 1...steps {
                    try? await Task.sleep(for: stepDuration)
                    guard !Task.isCancelled else { return }
                    progress[index] = Double(step) / Double(steps)
                }
            }
            guard repeats else { break }
        } while !Task.isCancelled
        if !repeats {
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}

#Preview {
    PersonalisingLoader(
        phases: [
            .init(label: "Analysing your profile…", duration: 1.2),
            .init(label: "Understanding your needs…", duration: 1.2),
            .init(label: "Finding your best first rep…", duration: 1.2)
        ],
        onFinished: {}
    )
    .padding()
    .background(CouchTheme.warmBackgroundGradient)
}

import SwiftUI

/// Launch splash: full-bleed blue, centred logomark that scales in with a
/// spring, bottom-centre wordmark + powered-by credit. Auto-dismisses via
/// the callback once `minimumDuration` has elapsed.
struct SplashView: View {
    var minimumDuration: Duration = .milliseconds(700)
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            CouchTheme.heroBackground
                .ignoresSafeArea()

            VStack(spacing: CouchTheme.Spacing.lg) {
                Spacer()
                LogoMark(style: .pill, height: 120, tint: .white, accent: CouchTheme.primary)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.7)
                    .opacity(appeared || reduceMotion ? 1 : 0)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.72),
                        value: appeared
                    )
                Spacer()
                footer
            }
            .padding(.bottom, CouchTheme.Spacing.xl)
        }
        .couchStatusBar(.onHero)
        .task {
            appeared = true
            try? await Task.sleep(for: minimumDuration)
            onFinished()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Couch is loading")
    }

    private var footer: some View {
        VStack(spacing: CouchTheme.Spacing.xxs) {
            Text("COUCH")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .tracking(6)
            Text("PRACTICE THERAPY BEFORE IT COUNTS")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(2.4)
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}

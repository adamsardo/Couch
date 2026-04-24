import SwiftUI

/// Launch splash: plush mascot, wordmark, and clinical-skills promise. Auto-dismisses via
/// the callback once `minimumDuration` has elapsed.
struct SplashView: View {
    var minimumDuration: Duration = .milliseconds(700)
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            CouchTheme.brandWash
                .ignoresSafeArea()

            VStack(spacing: CouchTheme.Spacing.lg) {
                Spacer()
                Image("mascot-default")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 184, height: 184)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.7)
                    .opacity(appeared || reduceMotion ? 1 : 0)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.72),
                        value: appeared
                    )
                    .accessibilityHidden(true)
                Spacer()
                footer
            }
            .padding(.bottom, CouchTheme.Spacing.xl)
        }
        .couchStatusBar(.default)
        .task {
            appeared = true
            try? await Task.sleep(for: minimumDuration)
            onFinished()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Couch is loading")
    }

    private var footer: some View {
        VStack(spacing: CouchTheme.Spacing.sm) {
            LogoMark(style: .pill, height: 54)
            Text("Practice therapy before it counts.")
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.textSecondary)
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}

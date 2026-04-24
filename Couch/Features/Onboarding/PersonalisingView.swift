import SwiftData
import SwiftUI

struct PersonalisingView: View {
    let state: OnboardingState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let phases: [PersonalisingLoader.Phase] = [
        .init(label: "Reading your goals", duration: 1.2),
        .init(label: "Matching the right pressure level", duration: 1.2),
        .init(label: "Setting up your first rep", duration: 1.4)
    ]

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.xl) {
            Spacer(minLength: 44)

            VStack(spacing: CouchTheme.Spacing.lg) {
                MascotLoadingMark(reduceMotion: reduceMotion)

                VStack(spacing: CouchTheme.Spacing.sm) {
                    Text("Finding your first rep")
                        .font(CouchTheme.Typography.displayHeavy)
                        .foregroundStyle(CouchTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.82)

                    Text("A quick private setup so Marcus meets you at the right level.")
                        .font(CouchTheme.Typography.body)
                        .foregroundStyle(CouchTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, CouchTheme.Spacing.lg)
            }

            PersonalisingLoader(phases: phases, onFinished: onFinished)
                .padding(.horizontal, CouchTheme.Spacing.lg)

            Spacer(minLength: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.light)
        .task { SeedData.ensureScenariosExist(in: modelContext) }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.white,
                CouchTheme.primarySoft.opacity(0.55),
                Color.white
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func onFinished() {
        guard !Task.isCancelled else { return }
        state.advance(to: .scenarioMatch)
    }
}

private struct MascotLoadingMark: View {
    let reduceMotion: Bool
    @State private var isSpinning = false
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(CouchTheme.lavenderSoft.opacity(0.34))
                .frame(width: 178, height: 178)
                .scaleEffect(isBreathing && !reduceMotion ? 1.04 : 1)

            Circle()
                .stroke(CouchTheme.surface.opacity(0.9), lineWidth: 14)
                .frame(width: 148, height: 148)

            Circle()
                .trim(from: 0.08, to: 0.58)
                .stroke(
                    CouchTheme.accentGradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 148, height: 148)
                .rotationEffect(.degrees(isSpinning && !reduceMotion ? 360 : 0))

            Image("mascot-compact")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .shadow(color: CouchTheme.primary.opacity(0.16), radius: 18, x: 0, y: 14)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Setting up your practice rep")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.35).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

#Preview {
    NavigationStack { PersonalisingView(state: OnboardingState()) }
        .modelContainer(AppModelContainer.previewContainer())
}

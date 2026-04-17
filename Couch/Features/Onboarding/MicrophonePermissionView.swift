import SwiftUI

struct MicrophonePermissionView: View {
    let state: OnboardingState
    var onComplete: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            hero

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                HighlightedText(
                    fullText: "Your voice makes it real.",
                    highlight: "voice",
                    font: CouchTheme.Typography.title
                )
                Text("We'll ask iOS for microphone access on the next tap. Audio stays on your device during the live conversation — switch to text any time.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }

            Spacer()

            VStack(spacing: CouchTheme.Spacing.sm) {
                PrimaryButton(
                    title: state.micPermission == .granted ? "Continue" : "Allow microphone",
                    systemImage: state.micPermission == .granted ? "checkmark" : "mic.fill",
                    isLoading: isRequesting
                ) {
                    Task { await handlePrimary() }
                }
                Button("Use text mode instead") {
                    state.sessionMode = .text
                    onComplete()
                }
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.textSecondary)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.background)
    }

    private var hero: some View {
        ZStack {
            Circle()
                .fill(CouchTheme.primarySoft.opacity(0.7))
                .frame(width: 180, height: 180)
                .blur(radius: 20)
            Image(systemName: "mic.fill")
                .font(.system(size: 90, weight: .bold))
                .foregroundStyle(CouchTheme.accentGradient)
                .shadow(color: CouchTheme.primary.opacity(0.3), radius: 18, x: 0, y: 10)
        }
        .frame(height: 180)
        .padding(.top, CouchTheme.Spacing.md)
    }

    private func handlePrimary() async {
        if state.micPermission == .granted {
            state.sessionMode = .voice
            onComplete()
            return
        }
        isRequesting = true
        let result = await MicPermissionService.shared.request()
        state.micPermission = result
        isRequesting = false
        switch result {
        case .granted:
            state.sessionMode = .voice
            onComplete()
        case .denied:
            state.sessionMode = .text
            onComplete()
        case .undetermined:
            break
        }
    }
}

#Preview {
    NavigationStack {
        MicrophonePermissionView(state: OnboardingState(), onComplete: {})
    }
}

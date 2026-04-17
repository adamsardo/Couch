import SwiftUI

struct MicrophonePermissionView: View {
    @Bindable var state: OnboardingState
    var onComplete: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            VStack(spacing: CouchTheme.Spacing.md) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(CouchTheme.primary)
                Text("Voice makes it real")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("We'll ask iOS for microphone access on the next tap. Audio stays on your device for the live conversation. You can switch to text any time.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CouchTheme.Spacing.md)
            }

            Spacer()

            VStack(spacing: CouchTheme.Spacing.sm) {
                PrimaryButton(
                    title: state.micPermission == .granted ? "Continue" : "Allow microphone",
                    systemImage: state.micPermission == .granted ? "checkmark" : "mic",
                    isLoading: isRequesting
                ) {
                    Task { await handlePrimary() }
                }
                Button("Use text mode instead") {
                    state.sessionMode = .text
                    onComplete()
                }
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.primaryStrong)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.background)
        .navigationTitle("Microphone")
        .navigationBarTitleDisplayMode(.inline)
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

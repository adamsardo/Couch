import SwiftUI

struct NameView: View {
    @Bindable var state: OnboardingState
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            Text("What's your name?")
                .font(CouchTheme.Typography.display)
                .foregroundStyle(CouchTheme.textPrimary)
                .padding(.top, CouchTheme.Spacing.md)

            TextField("Your name", text: $state.name)
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.textPrimary)
                .focused($isFocused)
                .textContentType(.givenName)
                .submitLabel(.done)
                .onSubmit(advance)
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: CouchTheme.Radius.option, style: .continuous)
                        .fill(CouchTheme.surfaceMuted)
                )

            Spacer()

            PrimaryButton(
                title: "Continue",
                isEnabled: !trimmedName.isEmpty,
                action: advance
            )
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .navigationBarBackButtonHidden(true)
        .task { isFocused = true }
    }

    private var trimmedName: String {
        state.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func advance() {
        guard !trimmedName.isEmpty else { return }
        state.advance(to: .privacy)
    }
}

#Preview {
    NavigationStack { NameView(state: OnboardingState()) }
}

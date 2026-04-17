import SwiftUI

struct PrivacyConsentView: View {
    let state: OnboardingState

    @State private var notTherapy = false
    @State private var dataProcessing = false
    @State private var termsAccepted = false

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            hero

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                HighlightedText(
                    fullText: "Your wellbeing. Your privacy.",
                    highlight: "wellbeing",
                    font: CouchTheme.Typography.title
                )

                VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                    ConsentCheckRow(
                        text: "I understand and agree that Couch is not therapy, not medical care, and not a crisis service.",
                        isChecked: notTherapy,
                        action: { notTherapy.toggle() }
                    )
                    ConsentCheckRow(
                        text: "I agree to processing of my practice data on-device so Couch can personalise feedback. See more in [Privacy Policy](https://example.com/privacy).",
                        isChecked: dataProcessing,
                        action: { dataProcessing.toggle() }
                    )
                    ConsentCheckRow(
                        text: "I agree to the [Privacy Policy](https://example.com/privacy) and [Terms of Use](https://example.com/terms).",
                        isChecked: termsAccepted,
                        action: { termsAccepted.toggle() }
                    )
                }
            }

            Spacer()

            VStack(spacing: CouchTheme.Spacing.sm) {
                Button("Accept all") {
                    notTherapy = true
                    dataProcessing = true
                    termsAccepted = true
                    CouchHaptics.tap()
                }
                .font(CouchTheme.Typography.bodyEmphasized)
                .foregroundStyle(CouchTheme.textPrimary)

                PrimaryButton(title: "Continue", isEnabled: allAccepted) {
                    state.consentAccepted = true
                    state.advance(to: .socialProof)
                }
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
        .navigationBarBackButtonHidden(false)
    }

    private var allAccepted: Bool {
        notTherapy && dataProcessing && termsAccepted
    }

    private var hero: some View {
        ZStack {
            Circle()
                .fill(CouchTheme.primarySoft.opacity(0.6))
                .frame(width: 220, height: 220)
                .blur(radius: 30)

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 110, weight: .bold))
                .foregroundStyle(CouchTheme.accentGradient)
                .shadow(color: CouchTheme.primary.opacity(0.35), radius: 20, x: 0, y: 10)
        }
        .frame(height: 200)
    }
}

#Preview {
    NavigationStack { PrivacyConsentView(state: OnboardingState()) }
}

import SwiftUI

struct PrivacyConsentView: View {
    let state: OnboardingState

    @State private var notTherapy = false
    @State private var dataProcessing = false
    @State private var termsAccepted = false

    private let legalLinks = LegalLinks.current

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            hero

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                HighlightedText(
                    fullText: "Practice, not therapy. Private by default.",
                    highlight: "Private",
                    font: CouchTheme.Typography.title
                )

                VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                    ConsentCheckRow(
                        text: "I understand and agree that Couch is not therapy, not medical care, and not a crisis service.",
                        isChecked: notTherapy,
                        action: { notTherapy.toggle() }
                    )
                    ConsentCheckRow(
                        text: "I agree Couch can process the practice data needed to run reps and generate feedback.",
                        isChecked: dataProcessing,
                        action: { dataProcessing.toggle() }
                    )
                    ConsentCheckRow(
                        text: "I agree to the Privacy Policy and Terms of Use.",
                        isChecked: termsAccepted,
                        action: { termsAccepted.toggle() }
                    )
                    HStack(spacing: CouchTheme.Spacing.sm) {
                        Link("Privacy Policy", destination: legalLinks.privacyPolicy)
                            .accessibilityIdentifier("privacy-policy-link")
                        Text("·")
                            .foregroundStyle(CouchTheme.textMuted)
                        Link("Terms of Use", destination: legalLinks.termsOfUse)
                            .accessibilityIdentifier("terms-of-use-link")
                    }
                    .font(CouchTheme.Typography.caption.weight(.semibold))
                    .tint(CouchTheme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

                Image(systemName: CouchIcons.shieldCheck)
                .font(.system(size: 110, weight: .bold))
                .foregroundStyle(CouchTheme.accentGradient)
                .couchElevation(.lg, tint: CouchTheme.primary)
                .accessibilityHidden(true)
        }
        .frame(height: 200)
    }
}

#Preview {
    NavigationStack { PrivacyConsentView(state: OnboardingState()) }
}

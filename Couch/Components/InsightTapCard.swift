import SwiftUI

/// White rounded card on an orange gradient background, inviting the user to tap to read.
struct InsightTapCard: View {
    var title: String = "Your first insight is ready!"
    var subtitle: String = "Tap to read it"
    var onTap: () -> Void

    var body: some View {
        ZStack {
            CouchTheme.accentGradient.ignoresSafeArea()

            Button {
                CouchHaptics.tap()
                onTap()
            } label: {
                VStack(spacing: CouchTheme.Spacing.lg) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(CouchTheme.primary)
                        .padding(.top, CouchTheme.Spacing.xl)

                    Spacer()

                    Text(title)
                        .font(CouchTheme.Typography.title)
                        .foregroundStyle(CouchTheme.primary)
                        .multilineTextAlignment(.center)

                    Spacer()

                    Text(subtitle)
                        .font(CouchTheme.Typography.bodyEmphasized)
                        .foregroundStyle(CouchTheme.primary.opacity(0.8))
                        .padding(.bottom, CouchTheme.Spacing.xl)
                }
                .frame(maxWidth: 320, minHeight: 420)
                .padding(.horizontal, CouchTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: CouchTheme.primaryStrong.opacity(0.3), radius: 30, x: 0, y: 10)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    InsightTapCard(onTap: {})
}

import SwiftUI

/// Floating "Quick rep" accessory for the tab bar. Shown inline when the
/// tab bar is collapsed and elevated above the tab bar otherwise. Gives
/// the user a one-tap path into their next rep from anywhere in the app.
struct QuickRepAccessory: View {
    let scenario: Scenario
    var onStart: () -> Void

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        Button {
            CouchHaptics.tap()
            onStart()
        } label: {
            HStack(spacing: CouchTheme.Spacing.sm) {
                ScenarioPortraitView(scenario: scenario, crop: .avatar(32))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Quick rep")
                        .font(CouchTheme.Typography.pill)
                        .foregroundStyle(CouchTheme.textPrimary)
                    if placement != .inline {
                        Text("with \(scenario.patientName)")
                            .font(CouchTheme.Typography.caption)
                            .foregroundStyle(CouchTheme.textSecondary)
                    }
                }

                Spacer(minLength: CouchTheme.Spacing.sm)

                Image(systemName: "play.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(CouchTheme.Spacing.sm)
                    .background(Circle().fill(CouchTheme.textPrimary))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, CouchTheme.Spacing.sm)
            .padding(.vertical, CouchTheme.Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.couchPress)
        .accessibilityLabel("Start quick rep with \(scenario.patientName)")
    }
}

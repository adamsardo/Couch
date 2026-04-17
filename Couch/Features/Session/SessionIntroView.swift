import SwiftUI

struct SessionIntroView: View {
    let scenario: Scenario
    var onStart: () -> Void

    @State private var autoAdvance = false

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Spacer(minLength: 0)
            VStack(spacing: CouchTheme.Spacing.md) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(CouchTheme.primary)
                Text("Meet \(scenario.patientName)")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text(scenario.openingCue)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CouchTheme.Spacing.md)
                Label(scenario.calmingCue, systemImage: "leaf.fill")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.success)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .couchGlassCard()
            Spacer(minLength: 0)
            PrimaryButton(title: "Start the rep", systemImage: "play.fill") {
                onStart()
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.background)
        .task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !autoAdvance {
                autoAdvance = true
            }
        }
    }
}

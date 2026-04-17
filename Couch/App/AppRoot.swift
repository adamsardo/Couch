import SwiftData
import SwiftUI

/// Routes between Onboarding and the tabbed home shell.
struct AppRoot: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.onboardedAt != nil {
                RootTabView(profile: profile)
            } else {
                OnboardingFlow()
            }
        }
        .task { ensureProfileExists() }
    }

    private func ensureProfileExists() {
        guard profiles.isEmpty else { return }
        modelContext.insert(UserProfile())
        try? modelContext.save()
    }
}

#Preview("Onboarding state") {
    AppRoot()
        .modelContainer(AppModelContainer.previewContainer())
}

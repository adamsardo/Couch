import SwiftData
import SwiftUI

/// Routes between Onboarding and Home based on whether the user has completed onboarding.
struct AppRoot: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.onboardedAt != nil {
                HomeView(profile: profile)
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

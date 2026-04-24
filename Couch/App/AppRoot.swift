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
        if let profile = profiles.first {
            configureForUITestsIfNeeded(profile)
            return
        }
        let profile = UserProfile()
        configureForUITestsIfNeeded(profile)
        modelContext.insert(profile)
        try? modelContext.save()
    }

    private func configureForUITestsIfNeeded(_ profile: UserProfile) {
        guard ProcessInfo.processInfo.arguments.contains("-CouchUITestOnboarded") else { return }
        profile.name = "Test"
        profile.yearLevel = YearLevel.postgrad.rawValue
        profile.placementWindow = PlacementWindow.thisSemester.rawValue
        profile.topStressor = FrictionStressor.anxiety.rawValue
        profile.stressors = [FrictionStressor.anxiety.rawValue]
        profile.goals = [PracticeGoal.buildConfidence.rawValue]
        profile.onboardedAt = profile.onboardedAt ?? .now
    }
}

#Preview("Onboarding state") {
    AppRoot()
        .modelContainer(AppModelContainer.previewContainer())
}

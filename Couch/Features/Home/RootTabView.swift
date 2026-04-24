import SwiftData
import SwiftUI

/// Tab-bar shell shown after onboarding: Practice / Progress / Settings.
/// Adopts iOS 26 tab-bar behaviors: minimize-on-scroll and a floating
/// "Run a rep" accessory that lives above the tab bar.
struct RootTabView: View {
    @Bindable var profile: UserProfile

    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]
    @State private var presentedScenario: Scenario?

    private var primaryScenario: Scenario? {
        scenarios.first(where: { $0.id == ScenarioCatalog.marcus.id }) ?? scenarios.first
    }

    var body: some View {
        TabView {
            Tab("Practice", systemImage: CouchIcons.practice) {
                HomeView(profile: profile)
            }
            Tab("Progress", systemImage: CouchIcons.progress) {
                HistoryView()
            }
            Tab("Settings", systemImage: CouchIcons.settings) {
                SettingsView(profile: profile)
            }
        }
        .tint(CouchTheme.primary)
        .preferredColorScheme(.light)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            if let scenario = primaryScenario {
                QuickRepAccessory(scenario: scenario) {
                    presentedScenario = scenario
                }
            }
        }
        .fullScreenCover(item: $presentedScenario) { scenario in
            SessionContainer(
                scenario: scenario,
                mode: .voice,
                onClose: { presentedScenario = nil }
            )
        }
    }
}

#Preview {
    RootTabView(profile: UserProfile(name: "Adam", onboardedAt: .now))
        .modelContainer(AppModelContainer.previewContainer())
}

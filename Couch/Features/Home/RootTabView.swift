import SwiftData
import SwiftUI

/// Tab-bar shell shown after onboarding: AI patient / History / Settings.
/// Adopts iOS 26 tab-bar behaviors: minimize-on-scroll and a floating
/// "Quick rep" accessory that lives above the tab bar.
struct RootTabView: View {
    @Bindable var profile: UserProfile

    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]
    @State private var presentedScenario: Scenario?

    private var primaryScenario: Scenario? {
        scenarios.first(where: { $0.id == ScenarioCatalog.marcus.id }) ?? scenarios.first
    }

    var body: some View {
        TabView {
            Tab("AI patient", systemImage: "waveform.circle.fill") {
                HomeView(profile: profile)
            }
            Tab("History", systemImage: "list.clipboard") {
                HistoryView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView(profile: profile)
            }
        }
        .tint(CouchTheme.primary)
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

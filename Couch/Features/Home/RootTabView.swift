import SwiftData
import SwiftUI

/// Tab-bar shell shown after onboarding: AI patient / History / Settings.
struct RootTabView: View {
    @Bindable var profile: UserProfile

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
    }
}

#Preview {
    RootTabView(profile: UserProfile(name: "Adam", onboardedAt: .now))
        .modelContainer(AppModelContainer.previewContainer())
}

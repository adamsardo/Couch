import SwiftData
import SwiftUI

struct SettingsView: View {
    @Bindable var profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [Session]
    @Query private var streakEvents: [StreakEvent]

    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: nameBinding)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(CouchTheme.textSecondary)
                    }
                }

                Section("Notifications") {
                    Toggle("Allow reminders", isOn: $profile.notificationsEnabled)
                        .tint(CouchTheme.primary)
                }

                Section("About") {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete my data", systemImage: "trash")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CouchTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert("Delete all local data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteEverything() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Sessions, reflections, and preferences will be removed from this device. This can't be undone.")
            }
            .onChange(of: profile.notificationsEnabled) { _, _ in
                try? modelContext.save()
            }
        }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { profile.name ?? "" },
            set: { newValue in
                profile.name = newValue.isEmpty ? nil : newValue
                try? modelContext.save()
            }
        )
    }

    private func deleteEverything() {
        for session in sessions {
            modelContext.delete(session)
        }
        for event in streakEvents {
            modelContext.delete(event)
        }
        profile.onboardedAt = nil
        profile.name = nil
        profile.yearLevel = nil
        profile.placementWindow = nil
        profile.topStressor = nil
        profile.stressors = []
        profile.goals = []
        profile.notificationsEnabled = false
        profile.ahaShown = false
        try? modelContext.save()
    }
}

#Preview {
    SettingsView(profile: UserProfile(name: "Adam", onboardedAt: .now))
        .modelContainer(AppModelContainer.previewContainer())
}

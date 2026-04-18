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
                Section {
                    profileRow
                } header: {
                    Text("Profile").textCase(nil)
                }

                Section("Notifications") {
                    Toggle("Allow reminders", isOn: $profile.notificationsEnabled)
                        .tint(CouchTheme.primary)
                }

                Section("About") {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Label {
                                Text("Privacy Policy")
                            } icon: {
                                Image(systemName: "lock.shield")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(CouchTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CouchTheme.textMuted)
                                .accessibilityHidden(true)
                        }
                    }
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Label {
                                Text("Terms of Use")
                            } icon: {
                                Image(systemName: "doc.text")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(CouchTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CouchTheme.textMuted)
                                .accessibilityHidden(true)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label {
                            Text("Delete my data")
                        } icon: {
                            Image(systemName: "trash")
                                .symbolEffect(.bounce, value: confirmDelete)
                        }
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

    // MARK: - Profile row

    private var profileRow: some View {
        HStack(spacing: CouchTheme.Spacing.md) {
            avatar
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.xxs) {
                TextField("Your name", text: nameBinding)
                    .font(CouchTheme.Typography.bodyEmphasized)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text(profile.yearLevel ?? "Add your year level")
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, CouchTheme.Spacing.xxs)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(CouchTheme.primarySoft)
                .frame(width: 48, height: 48)
            Text(String((profile.name ?? "C").prefix(1)).uppercased())
                .font(CouchTheme.Typography.cardTitle)
                .foregroundStyle(CouchTheme.textPrimary)
        }
        .accessibilityHidden(true)
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

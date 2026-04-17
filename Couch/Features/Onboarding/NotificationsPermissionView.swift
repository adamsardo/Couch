import SwiftUI
import UserNotifications

struct NotificationsPermissionView: View {
    let state: OnboardingState

    @State private var isRequesting = false

    var body: some View {
        VStack(alignment: .leading, spacing: CouchTheme.Spacing.lg) {
            previewStack

            Spacer(minLength: 0)

            Text("Get nudged so you don't skip your rep.")
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
                .multilineTextAlignment(.leading)

            PrimaryButton(
                title: "Continue",
                isLoading: isRequesting
            ) {
                Task { await requestNotifications() }
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CouchTheme.background)
    }

    private var previewStack: some View {
        VStack(spacing: CouchTheme.Spacing.sm) {
            notificationPreview(
                title: "Session is about to start",
                body: "Tap to begin your rep with Marcus",
                time: "10:15 PM"
            )
            notificationPreview(
                title: "New insights are ready",
                body: "Read your debrief from last night's rep",
                time: "4:56 PM"
            )
        }
        .padding(.top, CouchTheme.Spacing.xl)
    }

    private func notificationPreview(title: String, body: String, time: String) -> some View {
        HStack(alignment: .top, spacing: CouchTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(CouchTheme.accentGradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(CouchTheme.Typography.bodyEmphasized)
                        .foregroundStyle(CouchTheme.textPrimary)
                    Spacer()
                    Text(time)
                        .font(CouchTheme.Typography.caption)
                        .foregroundStyle(CouchTheme.textMuted)
                }
                Text(body)
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
        }
        .padding(CouchTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CouchTheme.background)
                .shadow(color: CouchTheme.textPrimary.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private func requestNotifications() async {
        isRequesting = true
        defer { isRequesting = false }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            state.notificationsGranted = granted
        } catch {
            state.notificationsGranted = false
        }
        state.advance(to: .microphone)
    }
}

#Preview {
    NavigationStack { NotificationsPermissionView(state: OnboardingState()) }
}

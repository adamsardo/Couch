import SwiftUI

/// Single, opinionated CTA button used everywhere a screen has one clear next action.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var role: ButtonRole? = nil
    let action: () -> Void

    var body: some View {
        Button(role: role) {
            CouchHaptics.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(CouchTheme.surface)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(CouchTheme.Typography.bodyEmphasized)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, CouchTheme.Spacing.md)
            .foregroundStyle(role == .destructive ? Color.white : CouchTheme.surface)
            .background(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.control, style: .continuous)
                    .fill(role == .destructive ? AnyShapeStyle(CouchTheme.danger) : AnyShapeStyle(LinearGradient(
                        colors: [CouchTheme.primary, CouchTheme.primaryStrong],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )))
            )
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// Quieter secondary action used alongside `PrimaryButton`.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            CouchHaptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(CouchTheme.Typography.bodyEmphasized)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, CouchTheme.Spacing.md)
            .foregroundStyle(CouchTheme.primaryStrong)
            .background(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.control, style: .continuous)
                    .strokeBorder(CouchTheme.primary.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Start free practice", systemImage: "waveform") {}
        PrimaryButton(title: "Loading…", isLoading: true) {}
        SecondaryButton(title: "Skip for now") {}
        PrimaryButton(title: "End session", role: .destructive) {}
    }
    .padding()
    .background(CouchTheme.background)
}

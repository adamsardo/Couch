import SwiftUI

/// Primary CTA used at the bottom of every flow-driven screen.
///
/// Two visual styles:
/// - `.primary` (default): near-black pill with white label. Used on white
///   or soft-blue surfaces.
/// - `.onHero`: white pill with near-black label. Used on full-bleed
///   `heroBackground` blue screens (social proof, science curve).
struct PrimaryButton: View {
    enum Style {
        case primary
        case onHero
    }

    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var role: ButtonRole? = nil
    var style: Style = .primary
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
                        .tint(progressTint)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(CouchTheme.Typography.pillCTA)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, CouchTheme.Spacing.md)
            .foregroundStyle(labelColor)
            .background(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.control, style: .continuous)
                    .fill(backgroundFill)
            )
        }
        .disabled(isLoading || !isEnabled)
        .buttonStyle(.couchPress)
        .animation(CouchMotion.pressFeedback, value: isEnabled)
        .animation(CouchMotion.pressFeedback, value: isLoading)
        .accessibilityLabel(title)
    }

    private var labelColor: Color {
        if role == .destructive { return .white }
        switch style {
        case .primary:
            if !isEnabled { return CouchTheme.textMuted }
            return .white
        case .onHero:
            if !isEnabled { return CouchTheme.textMuted }
            return CouchTheme.textPrimary
        }
    }

    private var backgroundFill: Color {
        if role == .destructive { return CouchTheme.danger }
        switch style {
        case .primary:
            if !isEnabled { return CouchTheme.surfaceMuted }
            return CouchTheme.textPrimary
        case .onHero:
            if !isEnabled { return Color.white.opacity(0.6) }
            return .white
        }
    }

    private var progressTint: Color {
        switch style {
        case .primary: return .white
        case .onHero: return CouchTheme.textPrimary
        }
    }
}

/// Outlined pill used alongside `PrimaryButton` for lower-stakes actions.
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
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, CouchTheme.Spacing.md)
            .foregroundStyle(CouchTheme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: CouchTheme.Radius.control, style: .continuous)
                    .fill(CouchTheme.surfaceMuted)
            )
        }
        .buttonStyle(.couchPress)
        .accessibilityLabel(title)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", action: {})
        PrimaryButton(title: "Continue", isEnabled: false, action: {})
        PrimaryButton(title: "Loading…", isLoading: true, action: {})
        PrimaryButton(title: "Sign in", style: .onHero, action: {})
            .padding()
            .background(CouchTheme.heroBackground)
        SecondaryButton(title: "Plan conversation", systemImage: "clock") {}
        PrimaryButton(title: "End session", role: .destructive, action: {})
    }
    .padding()
    .background(CouchTheme.background)
}

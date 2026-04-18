import SwiftUI

/// In-call control bar. Mute is a neutral glass disc that turns red only
/// when muted (matches the reference hierarchy: one red = End); End stays
/// red. Secondary Stuck / Text chips use glass capsules so they stay
/// legible over any portrait.
struct CallControlBar: View {
    let isMuted: Bool
    let mode: SessionMode
    var onMuteToggle: () -> Void
    var onFreezeHelp: () -> Void
    var onTextPanel: () -> Void
    var onEnd: () -> Void

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.xs) {
            HStack(alignment: .top, spacing: 48) {
                muteButton
                endButton
            }

            HStack(spacing: CouchTheme.Spacing.lg) {
                smallGhostButton(
                    systemImage: "lifepreserver",
                    label: "Stuck",
                    action: onFreezeHelp
                )
                smallGhostButton(
                    systemImage: mode == .text ? "keyboard.fill" : "keyboard",
                    label: "Text",
                    action: onTextPanel
                )
            }
            .padding(.top, CouchTheme.Spacing.xxs)
        }
        .padding(.horizontal, CouchTheme.Spacing.lg)
        .padding(.bottom, CouchTheme.Spacing.md)
    }

    // MARK: - Primary buttons

    private var muteButton: some View {
        VStack(spacing: CouchTheme.Spacing.sm) {
            Button {
                CouchHaptics.tap()
                onMuteToggle()
            } label: {
                Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 72, height: 72)
                    .background {
                        if isMuted {
                            Circle().fill(CouchTheme.danger)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                                )
                        }
                    }
            }
            .buttonStyle(.couchPress)
            .accessibilityLabel(isMuted ? "Unmute microphone" : "Mute microphone")

            Text(isMuted ? "Muted" : "Mute")
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var endButton: some View {
        VStack(spacing: CouchTheme.Spacing.sm) {
            Button {
                CouchHaptics.tap()
                onEnd()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(CouchTheme.danger))
            }
            .buttonStyle(.couchPress)
            .accessibilityLabel("End session")

            Text("End")
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Secondary chips

    @ViewBuilder
    private func smallGhostButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            CouchHaptics.tap()
            action()
        } label: {
            HStack(spacing: CouchTheme.Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.semibold))
                    .accessibilityHidden(true)
                Text(label)
                    .font(CouchTheme.Typography.pill)
            }
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, CouchTheme.Spacing.md)
            .padding(.vertical, CouchTheme.Spacing.xs + 2)
            .couchGlassCapsule()
        }
        .buttonStyle(.couchPress)
        .accessibilityLabel(label)
    }
}

/// Text-mode fallback panel surfaced as a sheet from the call UI.
struct CallTextPanel: View {
    @Binding var draft: String
    var onSend: (String) -> Void

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.md) {
            HStack {
                Text("Type your response")
                    .font(CouchTheme.Typography.sectionTitle)
                    .foregroundStyle(CouchTheme.textPrimary)
                Spacer()
            }

            TextField("Say it in words…", text: $draft, axis: .vertical)
                .lineLimit(1...6)
                .textFieldStyle(.plain)
                .padding(.horizontal, CouchTheme.Spacing.md)
                .padding(.vertical, CouchTheme.Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: CouchTheme.Radius.option, style: .continuous)
                        .fill(CouchTheme.surfaceMuted)
                )
                .focused($focused)

            PrimaryButton(title: "Send", systemImage: "arrow.up", isEnabled: canSend) {
                let text = draft
                draft = ""
                onSend(text)
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .background(CouchTheme.background)
        .onAppear { focused = true }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

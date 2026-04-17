import SwiftUI

/// Dark call-style control bar: two large red circular buttons (Mute / End) with
/// tiny extras on the left for text-fallback and freeze help, surfaced via a sheet.
struct CallControlBar: View {
    let isMuted: Bool
    let mode: SessionMode
    var onMuteToggle: () -> Void
    var onFreezeHelp: () -> Void
    var onTextPanel: () -> Void
    var onEnd: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 48) {
                controlButton(
                    systemImage: isMuted ? "mic.slash.fill" : "mic.fill",
                    label: isMuted ? "Muted" : "Mute",
                    filled: true,
                    action: onMuteToggle
                )
                controlButton(
                    systemImage: "phone.down.fill",
                    label: "End",
                    filled: true,
                    action: onEnd
                )
            }

            HStack(spacing: 24) {
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
            .padding(.top, 4)
        }
        .padding(.horizontal, CouchTheme.Spacing.lg)
        .padding(.bottom, CouchTheme.Spacing.md)
    }

    @ViewBuilder
    private func controlButton(systemImage: String, label: String, filled: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Button {
                CouchHaptics.tap()
                action()
            } label: {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(CouchTheme.danger))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
            Text(label)
                .font(CouchTheme.Typography.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    @ViewBuilder
    private func smallGhostButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            CouchHaptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.semibold))
                Text(label)
                    .font(CouchTheme.Typography.pill)
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(CouchTheme.callSurfaceMuted)
            )
        }
        .buttonStyle(.plain)
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
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
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

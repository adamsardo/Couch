import SwiftUI

struct SessionControlBar: View {
    @Binding var draft: String
    let mode: SessionMode
    let isMuted: Bool
    var onSend: (String) -> Void
    var onMuteToggle: () -> Void
    var onFreezeHelp: () -> Void
    var onEnd: () -> Void

    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.sm) {
            HStack(spacing: 8) {
                if mode == .voice {
                    iconButton(systemImage: isMuted ? "mic.slash.fill" : "mic.fill",
                               label: isMuted ? "Unmute" : "Mute",
                               tint: isMuted ? CouchTheme.danger : CouchTheme.primary,
                               action: onMuteToggle)
                }
                iconButton(systemImage: "lifepreserver",
                           label: "Stuck for a sec",
                           tint: CouchTheme.warning,
                           action: onFreezeHelp)
                Spacer()
                iconButton(systemImage: "stop.fill",
                           label: "End session",
                           tint: CouchTheme.danger,
                           action: onEnd)
            }

            HStack(spacing: 8) {
                TextField("Type if it's easier than speaking…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: CouchTheme.Radius.control, style: .continuous)
                            .fill(CouchTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CouchTheme.Radius.control, style: .continuous)
                            .strokeBorder(CouchTheme.divider, lineWidth: 1)
                    )
                    .focused($isInputFocused)

                Button {
                    let text = draft
                    draft = ""
                    onSend(text)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(canSend ? CouchTheme.primary : CouchTheme.textMuted)
                }
                .disabled(!canSend)
                .accessibilityLabel("Send")
            }
        }
        .padding(CouchTheme.Spacing.md)
        .background(CouchTheme.background)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private func iconButton(systemImage: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            CouchHaptics.tap()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(CouchTheme.surface)
                )
                .overlay(Circle().strokeBorder(CouchTheme.divider, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }
}

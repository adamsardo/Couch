import SwiftUI

enum TranscriptAppearance {
    case light
    case dark
}

/// Renders the live conversation transcript. Supports light (post-session) and
/// dark (in-call) appearances. Uses a stable identity for cheap diffing per
/// SwiftUI ForEach correctness rules.
struct TranscriptView: View {
    let turns: [DisplayTurn]
    let scenario: Scenario
    var appearance: TranscriptAppearance = .light

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                    if turns.isEmpty {
                        EmptyStateBubble(
                            text: "\(scenario.patientName) is in the room. Start when you're ready — a simple opener is fine.",
                            appearance: appearance
                        )
                    } else {
                        ForEach(turns) { turn in
                            TurnBubble(
                                turn: turn,
                                patientName: scenario.patientName,
                                appearance: appearance
                            )
                            .id(turn.id)
                        }
                    }
                }
                .padding(.vertical, CouchTheme.Spacing.md)
                .padding(.horizontal, CouchTheme.Spacing.md)
            }
            .onChange(of: turns.last?.id) { _, newID in
                guard let newID else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(newID, anchor: .bottom)
                }
            }
        }
    }
}

private struct TurnBubble: View {
    let turn: DisplayTurn
    let patientName: String
    let appearance: TranscriptAppearance

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            switch appearance {
            case .light:
                lightBubble
            case .dark:
                darkBubble
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var lightBubble: some View {
        HStack {
            if turn.role == .user { Spacer(minLength: 32) }
            VStack(alignment: turn.role == .user ? .trailing : .leading, spacing: 4) {
                Text(label)
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
                Text(turn.text)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(lightBackground)
                    )
                    .frame(maxWidth: 320, alignment: turn.role == .user ? .trailing : .leading)
            }
            if turn.role != .user { Spacer(minLength: 32) }
        }
    }

    @ViewBuilder
    private var darkBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            avatarBadge
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(CouchTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(darkLabelColor)
                Text(turn.text)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var avatarBadge: some View {
        Group {
            switch turn.role {
            case .user:
                Circle()
                    .fill(CouchTheme.primary)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("A")
                            .font(CouchTheme.Typography.caption.weight(.bold))
                            .foregroundStyle(.white)
                    )
            case .agent:
                Circle()
                    .fill(CouchTheme.callCaption.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(String(patientName.prefix(1)))
                            .font(CouchTheme.Typography.caption.weight(.bold))
                            .foregroundStyle(CouchTheme.callCaption)
                    )
            case .system:
                Circle()
                    .fill(CouchTheme.warning.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "lifepreserver")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CouchTheme.warning)
                    )
            }
        }
    }

    private var label: String {
        switch turn.role {
        case .user: return "You"
        case .agent: return patientName
        case .system: return "Prompt"
        }
    }

    private var lightBackground: Color {
        switch turn.role {
        case .user: return CouchTheme.primary.opacity(0.16)
        case .agent: return CouchTheme.surfaceMuted
        case .system: return CouchTheme.warning.opacity(0.18)
        }
    }

    private var darkLabelColor: Color {
        switch turn.role {
        case .user: return CouchTheme.primary
        case .agent: return CouchTheme.callCaption
        case .system: return CouchTheme.warning
        }
    }
}

private struct EmptyStateBubble: View {
    let text: String
    let appearance: TranscriptAppearance

    var body: some View {
        Text(text)
            .font(CouchTheme.Typography.body)
            .foregroundStyle(appearance == .dark ? Color.white.opacity(0.7) : CouchTheme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(CouchTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(appearance == .dark ? CouchTheme.callSurfaceMuted : CouchTheme.surfaceMuted)
            )
    }
}

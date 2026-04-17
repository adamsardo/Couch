import SwiftUI

/// Renders the live conversation transcript. Uses a stable identity for cheap diffing
/// per the SwiftUI ForEach correctness rules.
struct TranscriptView: View {
    let turns: [DisplayTurn]
    let scenario: Scenario

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                    if turns.isEmpty {
                        EmptyStateBubble(text: "Marcus is in the room. Start when you're ready — a simple opener is fine.")
                    } else {
                        ForEach(turns) { turn in
                            TurnBubble(turn: turn, patientName: scenario.patientName)
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

    var body: some View {
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
                            .fill(background)
                    )
                    .frame(maxWidth: 320, alignment: turn.role == .user ? .trailing : .leading)
            }
            if turn.role != .user { Spacer(minLength: 32) }
        }
        .accessibilityElement(children: .combine)
    }

    private var label: String {
        switch turn.role {
        case .user: return "You"
        case .agent: return patientName
        case .system: return "Prompt"
        }
    }

    private var background: Color {
        switch turn.role {
        case .user: return CouchTheme.primary.opacity(0.16)
        case .agent: return CouchTheme.surface
        case .system: return CouchTheme.warning.opacity(0.18)
        }
    }
}

private struct EmptyStateBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(CouchTheme.Typography.body)
            .foregroundStyle(CouchTheme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(CouchTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(CouchTheme.surface)
            )
    }
}

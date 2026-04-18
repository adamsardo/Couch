import SwiftUI

enum TranscriptAppearance {
    case light
    case dark
}

/// Renders the live conversation transcript. Supports light (post-session)
/// and dark (in-call, overlaid on portrait) appearances. Uses a stable
/// identity for cheap diffing per SwiftUI ForEach correctness rules, and
/// asymmetric entrance transitions so streaming turns rise into place.
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
                        .id("empty")
                        .transition(.opacity.animation(CouchMotion.entrance))
                    } else {
                        ForEach(turns) { turn in
                            TurnBubble(
                                turn: turn,
                                patientName: scenario.patientName,
                                appearance: appearance
                            )
                            .id(turn.id)
                            .scrollTransition(topLeading: .animated(.easeOut(duration: CouchMotion.small)),
                                              bottomTrailing: .identity) { view, phase in
                                view
                                    .opacity(phase.isIdentity ? 1 : 0)
                                    .offset(y: phase.isIdentity ? 0 : -8)
                            }
                            .transition(.asymmetric(
                                insertion: .opacity
                                    .combined(with: .offset(y: 12))
                                    .animation(CouchMotion.entrance),
                                removal: .opacity.animation(CouchMotion.exit)
                            ))
                        }
                    }
                }
                .padding(.vertical, CouchTheme.Spacing.md)
                .padding(.horizontal, CouchTheme.Spacing.md)
                .animation(CouchMotion.stateChange, value: turns.count)
            }
            .onChange(of: turns.last?.id) { _, newID in
                guard let newID else { return }
                withAnimation(CouchMotion.entrance) {
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
        switch appearance {
        case .light:
            lightBubble
        case .dark:
            darkBubble
        }
    }

    @ViewBuilder
    private var lightBubble: some View {
        HStack {
            if turn.role == .user { Spacer(minLength: 32) }
            VStack(alignment: turn.role == .user ? .trailing : .leading, spacing: CouchTheme.Spacing.xxs) {
                Text(label)
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
                Text(turn.text)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textPrimary)
                    .padding(.horizontal, CouchTheme.Spacing.md)
                    .padding(.vertical, CouchTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CouchTheme.Radius.bubble, style: .continuous)
                            .fill(lightBackground)
                    )
                    .frame(maxWidth: 320, alignment: turn.role == .user ? .trailing : .leading)
            }
            if turn.role != .user { Spacer(minLength: 32) }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var darkBubble: some View {
        HStack(alignment: .top, spacing: CouchTheme.Spacing.sm) {
            avatarBadge
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.xxs) {
                Text(label)
                    .font(CouchTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(darkLabelColor)
                Text(turn.text)
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, CouchTheme.Spacing.md)
            .padding(.vertical, CouchTheme.Spacing.sm)
            .couchGlassRoundedRect(
                radius: CouchTheme.Radius.bubble,
                tint: turn.role == .user ? CouchTheme.primary.opacity(0.18) : nil
            )
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var avatarBadge: some View {
        Group {
            switch turn.role {
            case .user:
                Circle()
                    .fill(CouchTheme.primary)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Text("A")
                            .font(CouchTheme.Typography.caption.weight(.bold))
                            .foregroundStyle(.white)
                    )
            case .agent:
                Circle()
                    .fill(CouchTheme.callCaption.opacity(0.3))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Text(String(patientName.prefix(1)))
                            .font(CouchTheme.Typography.caption.weight(.bold))
                            .foregroundStyle(CouchTheme.callCaption)
                    )
            case .system:
                Circle()
                    .fill(CouchTheme.warning.opacity(0.3))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "lifepreserver")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CouchTheme.warning)
                    )
            }
        }
        .accessibilityHidden(true)
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
            .foregroundStyle(appearance == .dark ? Color.white.opacity(0.75) : CouchTheme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(CouchTheme.Spacing.md)
            .modifier(EmptyBubbleBackground(appearance: appearance))
    }
}

private struct EmptyBubbleBackground: ViewModifier {
    let appearance: TranscriptAppearance

    func body(content: Content) -> some View {
        let innerRadius = CouchTheme.Radius.inner(of: CouchTheme.Radius.bubble, padding: 2)
        switch appearance {
        case .dark:
            content.couchGlassRoundedRect(radius: innerRadius)
        case .light:
            content.background(
                RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                    .fill(CouchTheme.surfaceMuted)
            )
        }
    }
}

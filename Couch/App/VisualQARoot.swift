#if DEBUG
import SwiftUI

enum VisualQARoute: String {
    case sessionIntro
    case call
    case personalising
    case progress
    case settings
    case debriefLoading
    case debriefError
    case completion

    static var current: VisualQARoute? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-CouchVisualQA"),
              arguments.indices.contains(index + 1) else {
            return nil
        }
        return VisualQARoute(rawValue: arguments[index + 1])
    }
}

struct VisualQARoot: View {
    let route: VisualQARoute

    private var scenario: Scenario { ScenarioCatalog.marcusScenarioModel() }

    var body: some View {
        switch route {
        case .sessionIntro:
            SessionIntroView(scenario: scenario, onBack: {}, onStart: {})
        case .call:
            VisualCallScreen(scenario: scenario)
        case .personalising:
            NavigationStack {
                PersonalisingView(state: OnboardingState())
            }
        case .progress:
            HistoryView()
        case .settings:
            SettingsView(profile: UserProfile(name: "Adam", onboardedAt: .now))
        case .debriefLoading:
            DebriefGenerationView()
        case .debriefError:
            VisualDebriefErrorScreen()
        case .completion:
            VisualCompletionScreen()
        }
    }
}

private struct VisualCallScreen: View {
    let scenario: Scenario

    var body: some View {
        ZStack {
            AvatarStageView(
                scenario: scenario,
                track: nil,
                overlays: [.topScrim, .bottomScrim, .vignette]
            )

            VStack(spacing: 0) {
                VStack(spacing: CouchTheme.Spacing.xs) {
                    Text(scenario.patientName)
                        .font(CouchTheme.Typography.sectionTitle)
                        .foregroundStyle(.white)
                    Text("Virtual patient")
                        .font(CouchTheme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.74))
                    Label("Speaking", systemImage: "waveform")
                        .font(CouchTheme.Typography.pill)
                        .foregroundStyle(CouchTheme.callCaption)
                        .padding(.top, CouchTheme.Spacing.xs)
                }
                .padding(.top, CouchTheme.Spacing.lg)

                Spacer(minLength: 0)

                Text("\(scenario.patientName) is in the room. Start when you're ready — a simple opener is fine.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, CouchTheme.Spacing.md)
                    .padding(.vertical, CouchTheme.Spacing.sm)
                    .frame(maxWidth: 320, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: CouchTheme.Radius.bubble, style: .continuous)
                            .fill(.black.opacity(0.48))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CouchTheme.Radius.bubble, style: .continuous)
                            .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, CouchTheme.Spacing.lg)
                    .padding(.bottom, CouchTheme.Spacing.sm)

                CallControlBar(
                    isMuted: false,
                    mode: .voice,
                    onMuteToggle: {},
                    onFreezeHelp: {},
                    onTextPanel: {},
                    onEnd: {}
                )
                .padding(.bottom, CouchTheme.Spacing.md)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct VisualDebriefErrorScreen: View {
    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(CouchTheme.warning)
                .accessibilityHidden(true)
            Text("Couldn't generate your debrief")
                .font(CouchTheme.Typography.title)
                .foregroundStyle(CouchTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text("OpenAI could not authenticate this local build. Check the current Secrets.plist key, then try again.")
                .font(CouchTheme.Typography.body)
                .foregroundStyle(CouchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CouchTheme.Spacing.md)
            VStack(spacing: CouchTheme.Spacing.sm) {
                PrimaryButton(title: "Try again", systemImage: "arrow.clockwise") {}
                SecondaryButton(title: "Back to Practice") {}
            }
        }
        .padding(CouchTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.background.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}

private struct VisualCompletionScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: CouchTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(CouchTheme.peachSoft.opacity(0.68))
                        .frame(width: 144, height: 144)
                    Image("mascot-complete")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 118, height: 118)
                    Text("one rep stronger")
                        .font(CouchTheme.Typography.caption.weight(.bold))
                        .foregroundStyle(CouchTheme.primary)
                        .padding(.horizontal, CouchTheme.Spacing.sm)
                        .padding(.vertical, CouchTheme.Spacing.xxs)
                        .background(Capsule().fill(CouchTheme.surface))
                        .offset(y: 64)
                }

                VStack(spacing: CouchTheme.Spacing.xs) {
                    Text("Therapy is a skill.")
                        .font(CouchTheme.Typography.title)
                        .foregroundStyle(CouchTheme.textPrimary)
                    Text("You can run another low-stakes rep now or bank this as today's win.")
                        .font(CouchTheme.Typography.body)
                        .foregroundStyle(CouchTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: CouchTheme.Spacing.sm), count: 3), spacing: CouchTheme.Spacing.sm) {
                    StatTile(value: "0:24", caption: "Elapsed")
                    StatTile(value: "2", caption: "Turns")
                    StatTile(value: "20", caption: "Rapport")
                    StatTile(value: "3", caption: "Strengths")
                    StatTile(value: "3", caption: "Next moves")
                    StatTile(value: "5/5", caption: "Confidence")
                }

                PrimaryButton(title: "Run another rep", systemImage: "arrow.clockwise") {}
                SecondaryButton(title: "Back to Practice") {}
            }
            .padding(CouchTheme.Spacing.lg)
            .couchGlassCard()
            .padding(CouchTheme.Spacing.lg)
        }
        .background(CouchTheme.background.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}
#endif

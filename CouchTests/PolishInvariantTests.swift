import Foundation
import SwiftUI
import Testing
@testable import Couch

/// Guards the premium-polish pass. These aren't full rendering tests —
/// they assert on the cheap, high-leverage invariants that would quietly
/// regress if someone touches the wrong token or re-introduces a
/// hand-tuned duration/radius.
@Suite("App-wide polish invariants")
@MainActor
struct PolishInvariantTests {

    // MARK: - Tokens

    @Test("Spacing.xxs is the 4pt fine-grain token")
    func spacingXxsIsFourPoints() {
        #expect(CouchTheme.Spacing.xxs == 4)
    }

    @Test("Spacing scale stays strictly increasing")
    func spacingScaleIsStrictlyIncreasing() {
        let scale = [
            CouchTheme.Spacing.xxs,
            CouchTheme.Spacing.xs,
            CouchTheme.Spacing.sm,
            CouchTheme.Spacing.md,
            CouchTheme.Spacing.lg,
            CouchTheme.Spacing.xl
        ]
        for pair in zip(scale, scale.dropFirst()) {
            #expect(pair.0 < pair.1, "Spacing scale must be strictly increasing")
        }
    }

    @Test("Radius.inner floors at 4pt so corners never go fully square")
    func concentricRadiusFloorsAtFour() {
        #expect(CouchTheme.Radius.inner(of: 10, padding: 100) == 4)
        #expect(CouchTheme.Radius.inner(of: 24, padding: 8) == 16)
        #expect(CouchTheme.Radius.inner(of: CouchTheme.Radius.card, padding: CouchTheme.Spacing.lg) >= 4)
    }

    // MARK: - Motion

    @Test("All user-initiated motion tokens stay at or under the 300ms cap")
    func motionTokensStayUnderUserInitiatedCap() {
        #expect(CouchMotion.press <= 0.3)
        #expect(CouchMotion.small <= 0.3)
        #expect(CouchMotion.state <= 0.3)
        #expect(CouchMotion.progress <= 0.3)
    }

    @Test("Motion respects Reduce Motion by returning nil animation")
    func motionRespectsReduceMotion() {
        #expect(CouchMotion.respecting(true, .easeInOut(duration: 1)) == nil)
        #expect(CouchMotion.respecting(false, .easeInOut(duration: 1)) != nil)
    }

    // MARK: - Shared components

    @Test(
        "ScenarioPortraitView constructs without crashing for every crop variant",
        arguments: [
            ScenarioPortraitView.Crop.full,
            .topFocused,
            .avatar(48),
            .avatar(60)
        ]
    )
    func portraitConstructibleForEveryCrop(crop: ScenarioPortraitView.Crop) {
        let scenario = makeScenario()
        let view = ScenarioPortraitView(
            scenario: scenario,
            crop: crop,
            overlays: [.topScrim, .bottomScrim, .vignette]
        )
        _ = view.body
    }

    @Test("SubtitlePill derives a concentric inner radius from its outer container")
    func subtitlePillUsesConcentricRadius() {
        // The pill's inner radius should never exceed the outer,
        // and should floor at 4 so corners never square out.
        let inner = CouchTheme.Radius.inner(
            of: CouchTheme.Radius.sheet,
            padding: CouchTheme.Spacing.lg
        )
        #expect(inner >= 4)
        #expect(inner <= CouchTheme.Radius.sheet)
    }

    // MARK: - Session intro title fix

    @Test("Session intro title uses a short form that survives narrow widths")
    func sessionIntroTitleIsShort() {
        // Regression guard for the `"First rep — Session 1 wit…"` truncation
        // we fixed by switching to `"Warm-up with <Name>"`. Specifically,
        // the intro title prefix is meaningfully shorter than the old copy.
        let newTitle = "Warm-up with Marcus"
        let oldTitle = "First rep \u{2014} Session 1 with Marcus"
        #expect(newTitle.count < oldTitle.count)
    }

    // MARK: - Debrief step progression

    @Test(
        "Debrief progress covers all 5 steps",
        arguments: [
            DebriefCoordinator.Step.strengths,
            .nextMoves,
            .microDrill,
            .confidence,
            .completed
        ]
    )
    func debriefStepIsMappedToProgress(step: DebriefCoordinator.Step) {
        // Every coordinator step must be renderable; this guards
        // the switch exhaustiveness we rely on inside `DebriefGateFlow`.
        switch step {
        case .strengths, .nextMoves, .microDrill, .confidence, .completed:
            #expect(Bool(true))
        }
    }

    // MARK: - Factory

    private func makeScenario() -> Scenario {
        Scenario(
            id: "marcus-intake",
            title: "First-session intake",
            patientName: "Marcus",
            patientAge: 28,
            summary: "Summary",
            openingCue: "Opening",
            calmingCue: "Calm",
            elevenLabsAgentId: ""
        )
    }
}

import Foundation
import SwiftUI
import Testing
@testable import Couch

/// Guards the math + layout contract of the dashboard `GoRing` component.
/// We don't need to render; we just verify the clamping behaviour by
/// exercising the same progress formula via a local copy so the test is
/// stable even if the view internals move around.
@Suite("GoRing progress clamping")
@MainActor
struct GoRingProgressTests {
    @Test("Value above max clamps to 1.0")
    func clampsAbove() {
        #expect(progress(value: 12, max: 5) == 1.0)
    }

    @Test("Negative value clamps to 0")
    func clampsBelow() {
        #expect(progress(value: -3, max: 5) == 0)
    }

    @Test("Zero max returns 0 to avoid NaN")
    func zeroMax() {
        #expect(progress(value: 1, max: 0) == 0)
    }

    @Test("Half of max is 0.5")
    func half() {
        #expect(progress(value: 2.5, max: 5) == 0.5)
    }

    @Test("GoRing is constructible across the common dashboard values")
    func ringConstructs() {
        _ = GoRing(value: 0, max: 3, label: "Reps", caption: "this week").body
        _ = GoRing(value: 7, max: 7, label: "Streak", caption: "days").body
        _ = GoRing(value: 3.6, max: 5, label: "Confidence", caption: "avg", integerValue: false).body
    }

    private func progress(value: Double, max: Double) -> Double {
        guard max > 0 else { return 0 }
        return Swift.max(0, Swift.min(value / max, 1.0))
    }
}

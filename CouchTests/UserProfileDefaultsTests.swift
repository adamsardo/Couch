import Foundation
import Testing
@testable import Couch

/// Guards the additive `UserProfile` fields that drive Home's ring goal
/// and the Quick Rep accessory's default launch mode.
@Suite("UserProfile defaults")
struct UserProfileDefaultsTests {
    @Test("Weekly rep goal defaults to 3")
    func weeklyRepGoalDefault() {
        let profile = UserProfile()
        #expect(profile.weeklyRepGoal == 3)
    }

    @Test("Default session mode defaults to voice")
    func defaultSessionModeDefault() {
        let profile = UserProfile()
        #expect(profile.defaultSessionMode == .voice)
    }

    @Test("Default session mode setter round-trips through raw storage")
    func defaultSessionModeRoundTrip() {
        let profile = UserProfile()
        profile.defaultSessionMode = .text
        #expect(profile.defaultSessionModeRaw == SessionMode.text.rawValue)
        #expect(profile.defaultSessionMode == .text)
    }

    @Test("Init accepts custom goal and mode")
    func initPassesThrough() {
        let profile = UserProfile(weeklyRepGoal: 5, defaultSessionMode: .text)
        #expect(profile.weeklyRepGoal == 5)
        #expect(profile.defaultSessionMode == .text)
    }
}

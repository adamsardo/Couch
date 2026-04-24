import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String?
    var yearLevel: String?
    var placementWindow: String?
    var topStressor: String?
    var stressors: [String]
    var goals: [String]
    var notificationsEnabled: Bool
    var onboardedAt: Date?
    var ahaShown: Bool
    /// Weekly rep target used by the home dashboard ring. Defaults to 3.
    var weeklyRepGoal: Int
    /// Preferred default session mode (voice vs text) used when launching
    /// a rep from Home or the quick-rep accessory. Defaults to voice.
    var defaultSessionModeRaw: String

    init(
        name: String? = nil,
        yearLevel: String? = nil,
        placementWindow: String? = nil,
        topStressor: String? = nil,
        stressors: [String] = [],
        goals: [String] = [],
        notificationsEnabled: Bool = false,
        onboardedAt: Date? = nil,
        ahaShown: Bool = false,
        weeklyRepGoal: Int = 3,
        defaultSessionMode: SessionMode = .voice
    ) {
        self.name = name
        self.yearLevel = yearLevel
        self.placementWindow = placementWindow
        self.topStressor = topStressor
        self.stressors = stressors
        self.goals = goals
        self.notificationsEnabled = notificationsEnabled
        self.onboardedAt = onboardedAt
        self.ahaShown = ahaShown
        self.weeklyRepGoal = weeklyRepGoal
        self.defaultSessionModeRaw = defaultSessionMode.rawValue
    }

    var defaultSessionMode: SessionMode {
        get { SessionMode(rawValue: defaultSessionModeRaw) ?? .voice }
        set { defaultSessionModeRaw = newValue.rawValue }
    }
}

enum YearLevel: String, CaseIterable, Identifiable, Codable, Sendable {
    case third = "3rd year"
    case fourth = "4th year"
    case fifth = "5th year"
    case postgrad = "Postgrad"
    var id: String { rawValue }
}

enum PlacementWindow: String, CaseIterable, Identifiable, Codable, Sendable {
    case thisSemester = "This semester"
    case nextSemester = "Next semester"
    case thisYear = "Sometime this year"
    case unsure = "Not sure yet"
    var id: String { rawValue }
}

enum FrictionStressor: String, CaseIterable, Identifiable, Codable, Sendable {
    case timePoor = "I'm time-poor"
    case logistics = "Booking rooms or commuting"
    case anxiety = "Anxious about live practice"
    case noPracticePartner = "No practice partner"
    case troubleFocusing = "Trouble focusing"
    case perfectionism = "Fear of getting it wrong"
    case unsureWhatToSay = "Unsure what to say next"
    var id: String { rawValue }

    /// Copy used by the post-debrief "aha" payoff to mirror back the user's pain.
    var ahaPayoff: String {
        switch self {
        case .timePoor:
            return "You said you were time-poor. That rep took minutes — no booking, no commute."
        case .logistics:
            return "No room booking. No begging a classmate. Just one quiet rep, on your phone."
        case .anxiety:
            return "You just did a real rep, privately. No one watching. No one judging."
        case .noPracticePartner:
            return "You didn't need a partner. You had a real rep on your own schedule."
        case .troubleFocusing:
            return "You stayed with it for a full rep. That focus counts."
        case .perfectionism:
            return "You stumbled a little, and nothing broke. That's the reps doing their job."
        case .unsureWhatToSay:
            return "You found your words once, in a real rep. Next time will be easier."
        }
    }
}

enum PracticeGoal: String, CaseIterable, Identifiable, Codable, Sendable {
    case buildConfidence = "Build confidence"
    case practiseIntakes = "Practise intakes"
    case handleResistance = "Work with defensiveness"
    case manageFreeze = "Manage freeze moments"
    case improveFeedbackUse = "Use feedback better"
    case prepForPlacement = "Prep for placement"
    case learnCalmingTools = "Learn quick calming tools"
    var id: String { rawValue }
}

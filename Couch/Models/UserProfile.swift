import Foundation
import SwiftData

@Model
final class UserProfile {
    var yearLevel: String?
    var placementWindow: String?
    var topStressor: String?
    var onboardedAt: Date?
    var ahaShown: Bool

    init(
        yearLevel: String? = nil,
        placementWindow: String? = nil,
        topStressor: String? = nil,
        onboardedAt: Date? = nil,
        ahaShown: Bool = false
    ) {
        self.yearLevel = yearLevel
        self.placementWindow = placementWindow
        self.topStressor = topStressor
        self.onboardedAt = onboardedAt
        self.ahaShown = ahaShown
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
    case logistics = "Booking rooms / commuting"
    case anxiety = "Anxious about role-play"
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
        }
    }
}

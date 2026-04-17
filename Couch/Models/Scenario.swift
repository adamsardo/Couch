import Foundation
import SwiftData

@Model
final class Scenario {
    @Attribute(.unique) var id: String
    var title: String
    var patientName: String
    var patientAge: Int
    var summary: String
    var openingCue: String
    var calmingCue: String
    var elevenLabsAgentId: String
    var tags: [String]
    var createdAt: Date

    init(
        id: String,
        title: String,
        patientName: String,
        patientAge: Int,
        summary: String,
        openingCue: String,
        calmingCue: String,
        elevenLabsAgentId: String,
        tags: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.patientName = patientName
        self.patientAge = patientAge
        self.summary = summary
        self.openingCue = openingCue
        self.calmingCue = calmingCue
        self.elevenLabsAgentId = elevenLabsAgentId
        self.tags = tags
        self.createdAt = createdAt
    }
}

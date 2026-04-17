import Foundation
import OSLog

/// Generates the structured post-session debrief (3 strengths / 3 next moves / 1 micro-drill)
/// by sending the transcript to the OpenAI Responses API with a strict JSON Schema.
nonisolated struct DebriefService: Sendable {
    var modelName: String = "gpt-4.1-mini"

    func generate(
        scenario: ScenarioSnapshot,
        turns: [TurnSnapshot]
    ) async throws -> DebriefPayload {
        let instructions = Self.systemPrompt
        let input = Self.renderInput(scenario: scenario, turns: turns)
        Logger.debrief.info("Generating debrief for \(turns.count, privacy: .public) turns")
        return try await OpenAIClient.shared.generate(
            model: modelName,
            instructions: instructions,
            input: input,
            schemaName: "couch_debrief",
            schema: Self.jsonSchema,
            outputType: DebriefPayload.self
        )
    }

    /// JSON Schema for OpenAI structured outputs. Keep aligned with `DebriefPayload`.
    static let jsonSchema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["strengths", "next_moves", "micro_drill", "notes", "risk_flags"],
        "properties": [
            "strengths": [
                "type": "array",
                "minItems": 3,
                "maxItems": 3,
                "items": ["type": "string", "minLength": 8]
            ],
            "next_moves": [
                "type": "array",
                "minItems": 3,
                "maxItems": 3,
                "items": ["type": "string", "minLength": 8]
            ],
            "micro_drill": [
                "type": "object",
                "additionalProperties": false,
                "required": ["title", "body"],
                "properties": [
                    "title": ["type": "string", "minLength": 4, "maxLength": 80],
                    "body": ["type": "string", "minLength": 20, "maxLength": 320]
                ]
            ],
            "notes": ["type": "string", "maxLength": 600],
            "risk_flags": [
                "type": "array",
                "items": ["type": "string"]
            ]
        ]
    ]

    static let systemPrompt: String = """
    You are a clinical-skills coach for psychology students practising therapy reps in a
    simulator. The user just finished a SIMULATED session with a virtual patient. Your only
    job is to write a debrief that helps them get better next time.

    Output rules (non-negotiable):
    - This is TRAINING practice. Never imply the user is providing care or therapy.
    - Do NOT diagnose the patient, even tentatively.
    - Be SPECIFIC, not vague. Reference moments from the transcript ("when you reflected
      that work has been wearing him down…"). Avoid platitudes like "good listening".
    - Strengths: exactly 3, warm and credible, each one observable in the transcript.
    - Next moves: exactly 3, each a concrete behaviour to try in the NEXT rep.
    - Micro-drill: ONE focused practice prompt the user can carry into their next session,
      with a short title and 1–2 sentence body.
    - Notes: at most a couple of sentences for context. Optional but helpful.
    - Risk flags: only fill if the user did something the supervising clinician would want
      to flag (e.g. premature suicide screening before rapport, ignoring a clear distress
      signal). Otherwise return an empty array.

    Tone: specific, competent, non-judgmental, practical. No clinical jargon. No emoji.
    """

    static func renderInput(scenario: ScenarioSnapshot, turns: [TurnSnapshot]) -> String {
        var out = ""
        out += "Scenario: \(scenario.title) (patient: \(scenario.patientName), age \(scenario.patientAge))\n"
        out += "Summary: \(scenario.summary)\n\n"
        out += "Transcript (S = student, P = patient):\n"
        for turn in turns {
            let prefix: String
            switch turn.role {
            case .user: prefix = "S"
            case .agent: prefix = "P"
            case .system: prefix = "·"
            }
            out += "\(prefix): \(turn.text)\n"
        }
        return out
    }
}

nonisolated struct DebriefPayload: Codable, Sendable, Equatable {
    var strengths: [String]
    var nextMoves: [String]
    var microDrill: MicroDrillPayload
    var notes: String
    var riskFlags: [String]

    enum CodingKeys: String, CodingKey {
        case strengths
        case nextMoves = "next_moves"
        case microDrill = "micro_drill"
        case notes
        case riskFlags = "risk_flags"
    }
}

nonisolated struct MicroDrillPayload: Codable, Sendable, Equatable {
    var title: String
    var body: String
}

nonisolated struct ScenarioSnapshot: Sendable, Equatable {
    let id: String
    let title: String
    let patientName: String
    let patientAge: Int
    let summary: String
}

nonisolated struct TurnSnapshot: Sendable, Equatable {
    let role: TurnRole
    let text: String
}

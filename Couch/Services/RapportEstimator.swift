import Foundation

/// A deliberately simple, non-authoritative rapport estimator.
///
/// Used only for **display** in the session HUD and as a soft signal to the debrief LLM.
/// The real rapport state lives inside the ElevenLabs agent's prompt; this is a heuristic
/// summary the app uses so the user has a sense of momentum.
nonisolated struct RapportEstimator: Sendable {
    /// Score between 0 and 100. Starts at 20 (Marcus baseline), drifts up with reflection
    /// language and down with clinical/diagnostic language.
    func estimate(turns: [RapportTurn]) -> Int {
        var score: Double = 20
        for turn in turns where turn.role == .user {
            let text = turn.text.lowercased()
            score += Self.delta(for: text)
            score = min(100, max(0, score))
        }
        return Int(score.rounded())
    }

    private static func delta(for text: String) -> Double {
        var d: Double = 0
        for token in Self.positiveTokens where text.contains(token) {
            d += 4
        }
        for token in Self.negativeTokens where text.contains(token) {
            d -= 6
        }
        // Soft bonus for short, curious questions
        if text.hasSuffix("?") && text.count < 80 { d += 2 }
        return d
    }

    private static let positiveTokens = [
        "sounds like", "makes sense", "i hear you", "that's a lot",
        "what was that like", "tell me more", "no rush"
    ]
    private static let negativeTokens = [
        "depression", "diagnose", "diagnosis", "anhedonia",
        "have you ever thought", "self-harm", "kill yourself", "suicidal",
        "you should", "you need to"
    ]
}

nonisolated struct RapportTurn: Sendable, Equatable {
    let role: TurnRole
    let text: String
}

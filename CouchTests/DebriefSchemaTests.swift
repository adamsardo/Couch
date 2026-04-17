import Foundation
import Testing
@testable import Couch

@Suite("Debrief schema")
struct DebriefSchemaTests {
    @Test
    func decodeGoldenPayload() throws {
        let json = """
        {
          "strengths": [
            "You reflected what Marcus said about Jess.",
            "You waited a full beat before your next question.",
            "You normalised attending therapy without minimising."
          ],
          "next_moves": [
            "Try one short open question after his next sigh.",
            "Reflect feeling, not facts, when he mentions Jess.",
            "Avoid screening questions until rapport is in place."
          ],
          "micro_drill": {
            "title": "Reflect feeling, not facts",
            "body": "When he says 'I'm just tired', try 'sounds heavy' instead of 'how long has that been going on?'."
          },
          "notes": "Marcus warmed slightly when work came up.",
          "risk_flags": []
        }
        """
        let payload = try JSONDecoder().decode(DebriefPayload.self, from: Data(json.utf8))
        #expect(payload.strengths.count == 3)
        #expect(payload.nextMoves.count == 3)
        #expect(!payload.microDrill.title.isEmpty)
        #expect(payload.riskFlags.isEmpty)
    }

    @Test
    func envelopeExtractsTextFromOutputArray() throws {
        let payloadString = #"{\"strengths\":[\"a\",\"b\",\"c\"],\"next_moves\":[\"a\",\"b\",\"c\"],\"micro_drill\":{\"title\":\"t\",\"body\":\"bbbbbbbbbbbbbbbbbbbb\"},\"notes\":\"\",\"risk_flags\":[]}"#
        let envelope = """
        {
          "output": [{
            "content": [{
              "type": "output_text",
              "text": "\(payloadString)"
            }]
          }]
        }
        """
        let payload: DebriefPayload = try OpenAIClient.decodeStructuredOutput(
            data: Data(envelope.utf8),
            as: DebriefPayload.self
        )
        #expect(payload.strengths.count == 3)
    }

    @Test
    func systemPromptMentionsTrainingNotTherapy() {
        let prompt = DebriefService.systemPrompt
        #expect(prompt.localizedCaseInsensitiveContains("training"))
        #expect(prompt.localizedCaseInsensitiveContains("simulator") || prompt.localizedCaseInsensitiveContains("simulated"))
    }

    @Test
    func renderedInputContainsScenarioAndTurns() {
        let scenario = ScenarioSnapshot(
            id: "marcus-intake",
            title: "First-session intake",
            patientName: "Marcus",
            patientAge: 28,
            summary: "His partner referred him."
        )
        let turns = [
            TurnSnapshot(role: .user, text: "Tell me about why you're here."),
            TurnSnapshot(role: .agent, text: "I dunno. Jess thinks I need to talk.")
        ]
        let rendered = DebriefService.renderInput(scenario: scenario, turns: turns)
        #expect(rendered.contains("Marcus"))
        #expect(rendered.contains("S: Tell me"))
        #expect(rendered.contains("P: I dunno"))
    }
}

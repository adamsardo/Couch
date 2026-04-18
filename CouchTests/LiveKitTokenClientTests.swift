import Foundation
import Testing
@testable import Couch

@Suite("LiveKit token client")
struct LiveKitTokenClientTests {
    @Test
    func tokenRequestEncodesRequiredFields() throws {
        let request = LiveKitTokenRequest(
            scenarioID: "marcus-intake",
            mode: .voice,
            participantName: "Student",
            participantIdentity: "student-abc"
        )
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(decoded?["scenarioId"] as? String == "marcus-intake")
        #expect(decoded?["mode"] as? String == "voice")
        #expect(decoded?["participantName"] as? String == "Student")
        #expect(decoded?["participantIdentity"] as? String == "student-abc")
    }

    @Test
    func tokenResponseDecodesExpectedPayload() throws {
        let json = """
        {
          "serverUrl": "wss://demo.livekit.cloud",
          "participantToken": "eyJhbGciOi",
          "room": "couch-marcus-abc",
          "participantIdentity": "student-xyz",
          "session": {
            "scenarioId": "marcus-intake",
            "mode": "voice",
            "avatar": {
              "enabled": true,
              "provider": "lemonslice",
              "startTimeoutSeconds": 8.0
            }
          }
        }
        """
        let decoded = try JSONDecoder().decode(LiveKitTokenResponse.self, from: Data(json.utf8))
        #expect(decoded.serverUrl.hasPrefix("wss://"))
        #expect(decoded.session.avatar.enabled)
        #expect(decoded.session.avatar.provider == "lemonslice")
    }

    @Test
    func resolvedReturnsNilWhenSecretsUnset() {
        // Under CI the plist isn't present and env vars aren't injected, so
        // the client should cleanly report "not configured" instead of
        // constructing with garbage values.
        let client = LiveKitTokenClient.resolved()
        if SecretsProvider.shared.couchBackendBaseURL() == nil ||
           (SecretsProvider.shared.couchBackendSharedSecret() ?? "").isEmpty {
            #expect(client == nil)
        }
    }
}

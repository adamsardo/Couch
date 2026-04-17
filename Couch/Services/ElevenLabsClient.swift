import Foundation
import Combine
import ElevenLabs
import OSLog

/// Thin wrapper around the ElevenLabs Conversational AI Swift SDK.
///
/// The wrapper exists so the rest of the app talks to a small, testable surface and so
/// we never leak the SDK's `Conversation` type into views. It also makes it trivial to
/// swap to signed-URL auth later without touching the session UI.
@MainActor
final class ElevenLabsClient {
    static let shared = ElevenLabsClient()

    /// Start a public-agent conversation. Throws if the agentId is missing or the SDK
    /// fails to connect.
    func startConversation(
        agentId: String,
        textOnly: Bool
    ) async throws -> Conversation {
        guard !agentId.isEmpty else {
            throw ElevenLabsClientError.missingAgentID
        }
        let config = ConversationConfig(
            conversationOverrides: ConversationOverrides(textOnly: textOnly)
        )
        Logger.session.info("Starting ElevenLabs conversation (textOnly=\(textOnly, privacy: .public))")
        return try await ElevenLabs.startConversation(
            agentId: agentId,
            config: config
        )
    }
}

enum ElevenLabsClientError: LocalizedError {
    case missingAgentID

    var errorDescription: String? {
        switch self {
        case .missingAgentID:
            return "Missing ElevenLabs agent ID. Set MARCUS_AGENT_ID in Secrets.plist or your scheme env."
        }
    }
}

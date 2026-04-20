import Foundation
import OSLog

/// Payload posted to the backend token endpoint. Kept deliberately small —
/// the server is the source of truth for scenario config, prompts, and
/// avatar provider identity (PRD §6.4).
nonisolated struct LiveKitTokenRequest: Encodable, Sendable {
    let scenarioId: String
    let mode: String
    let participantName: String?
    let participantIdentity: String?

    init(scenarioID: String, mode: SessionMode, participantName: String?, participantIdentity: String?) {
        self.scenarioId = scenarioID
        self.mode = mode.rawValue
        self.participantName = participantName
        self.participantIdentity = participantIdentity
    }
}

/// Response shape from `POST /v1/sessions/token` on the Couch backend.
nonisolated struct LiveKitTokenResponse: Decodable, Sendable {
    nonisolated struct SessionBlock: Decodable, Sendable {
        nonisolated struct Avatar: Decodable, Sendable {
            let enabled: Bool
            let provider: String
            let startTimeoutSeconds: Double
        }
        let scenarioId: String
        let mode: String
        let avatar: Avatar
    }
    let serverUrl: String
    let participantToken: String
    let room: String
    let participantIdentity: String
    let session: SessionBlock
}

/// Small HTTP client that fetches LiveKit participant tokens from the Couch
/// backend. Every call authenticates with the shared secret stored only
/// on-device (never in the SPM code path of the LiveKit SDK).
actor LiveKitTokenClient {
    private let baseURL: URL
    private let sharedSecret: String
    private let session: URLSession

    init(baseURL: URL, sharedSecret: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.sharedSecret = sharedSecret
        self.session = session
    }

    /// Resolves a token using the provider values read from
    /// ``SecretsProvider``. Returns `nil` if the backend is not configured;
    /// the coordinator uses that signal to stay on the legacy transport.
    static func resolved(from provider: SecretsProvider = .shared) -> LiveKitTokenClient? {
        guard let url = provider.couchBackendBaseURL(),
              let secret = provider.couchBackendSharedSecret(), !secret.isEmpty
        else {
            return nil
        }
        return LiveKitTokenClient(baseURL: url, sharedSecret: secret)
    }

    /// POSTs a token request and returns the parsed response.
    func fetchToken(for request: LiveKitTokenRequest) async throws -> LiveKitTokenResponse {
        let endpoint = baseURL.appendingPathComponent("v1/sessions/token")
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(sharedSecret, forHTTPHeaderField: "X-Couch-Auth")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw LiveKitTokenClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            Logger.session.error("LiveKit token request failed: \(http.statusCode, privacy: .public) body=\(body, privacy: .public)")
            throw LiveKitTokenClientError.httpStatus(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(LiveKitTokenResponse.self, from: data)
        } catch {
            throw LiveKitTokenClientError.decodingFailed(error)
        }
    }
}

enum LiveKitTokenClientError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed(Error)
    case backendNotConfigured

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Couch backend returned an unexpected response."
        case .httpStatus(let code):
            return "Couch backend returned HTTP \(code)."
        case .decodingFailed(let underlying):
            return "Couldn't parse the token response: \(underlying.localizedDescription)"
        case .backendNotConfigured:
            return "Couch backend URL or shared secret is missing. Set COUCH_BACKEND_URL and COUCH_BACKEND_SHARED_SECRET."
        }
    }
}

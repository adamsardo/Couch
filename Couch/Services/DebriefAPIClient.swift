import Foundation
import OSLog

nonisolated struct DebriefAPIRequest: Encodable, Sendable {
    let scenario: ScenarioSnapshot
    let turns: [TurnSnapshot]
}

actor DebriefAPIClient {
    private let baseURL: URL
    private let sharedSecret: String
    private let session: URLSession

    init(baseURL: URL, sharedSecret: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.sharedSecret = sharedSecret
        self.session = session
    }

    static func resolved(from provider: SecretsProvider = .shared) -> DebriefAPIClient? {
        guard let url = provider.couchBackendBaseURL(),
              let secret = provider.couchBackendSharedSecret(),
              !secret.isEmpty
        else {
            return nil
        }
        return DebriefAPIClient(baseURL: url, sharedSecret: secret)
    }

    func generate(scenario: ScenarioSnapshot, turns: [TurnSnapshot]) async throws -> DebriefPayload {
        let started = ContinuousClock.now
        let endpoint = baseURL.appendingPathComponent("v1/debriefs")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sharedSecret, forHTTPHeaderField: "X-Couch-Auth")
        request.httpBody = try JSONEncoder().encode(DebriefAPIRequest(scenario: scenario, turns: turns))
        request.timeoutInterval = 75

        let (data, response) = try await session.data(for: request)
        let elapsedMs = started.duration(to: .now).components.seconds * 1_000
            + started.duration(to: .now).components.attoseconds / 1_000_000_000_000_000
        Logger.debrief.info("Debrief backend request completed in \(elapsedMs, privacy: .public)ms for \(turns.count, privacy: .public) turns")

        guard let http = response as? HTTPURLResponse else {
            throw DebriefAPIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            Logger.debrief.error("Debrief backend failed: \(http.statusCode, privacy: .public)")
            throw DebriefAPIError.httpStatus(http.statusCode, body: body)
        }
        return try JSONDecoder().decode(DebriefPayload.self, from: data)
    }
}

enum DebriefAPIError: LocalizedError {
    case invalidResponse
    case httpStatus(Int, body: String)
    case backendNotConfigured

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Couch backend returned an unexpected response."
        case .httpStatus(let status, _):
            return "Couch backend returned HTTP \(status)."
        case .backendNotConfigured:
            return "Couch backend URL or shared secret is missing. Set COUCH_BACKEND_URL and COUCH_BACKEND_SHARED_SECRET."
        }
    }
}

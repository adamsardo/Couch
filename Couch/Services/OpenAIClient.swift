import Foundation
import OSLog

/// Tiny URLSession-based client for the OpenAI Responses API with structured outputs.
/// Lives on its own actor so concurrent calls serialise around the URLSession instance.
actor OpenAIClient {
    static let shared = OpenAIClient()

    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Calls the Responses API and decodes the structured output into the requested type.
    /// `schemaName` and `schema` define the JSON Schema the model must produce.
    func generate<Output: Decodable & Sendable>(
        model: String,
        instructions: String,
        input: String,
        schemaName: String,
        schema: [String: Any],
        outputType: Output.Type
    ) async throws -> Output {
        guard let apiKey = SecretsProvider.shared.openAIAPIKey(), !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let payload: [String: Any] = [
            "model": model,
            "instructions": instructions,
            "input": input,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": schemaName,
                    "schema": schema,
                    "strict": true
                ]
            ]
        ]
        let body = try JSONSerialization.data(withJSONObject: payload, options: [])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 60

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIError.transport("non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "<no body>"
            Logger.llm.error("OpenAI error \(http.statusCode, privacy: .public): \(text, privacy: .public)")
            throw OpenAIError.http(status: http.statusCode, body: text)
        }

        return try Self.decodeStructuredOutput(data: data, as: Output.self)
    }

    /// Pulls the first text output from the Responses API envelope and JSON-decodes it.
    nonisolated static func decodeStructuredOutput<Output: Decodable>(data: Data, as outputType: Output.Type) throws -> Output {
        let envelope = try JSONDecoder().decode(ResponsesEnvelope.self, from: data)
        guard let raw = envelope.firstOutputText else {
            throw OpenAIError.decoding("missing output_text")
        }
        guard let payload = raw.data(using: .utf8) else {
            throw OpenAIError.decoding("output_text not utf8")
        }
        do {
            return try JSONDecoder().decode(Output.self, from: payload)
        } catch {
            throw OpenAIError.decoding("json: \(error.localizedDescription)")
        }
    }
}

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case transport(String)
    case http(status: Int, body: String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing OpenAI API key. Add OPENAI_API_KEY to Couch/Secrets.plist."
        case .transport(let detail):
            return "Network error: \(detail)"
        case .http(let status, _):
            return "OpenAI HTTP \(status)"
        case .decoding(let detail):
            return "Could not decode response: \(detail)"
        }
    }
}

/// Minimal slice of the Responses API envelope we care about for structured outputs.
nonisolated struct ResponsesEnvelope: Decodable, Sendable {
    let output: [Output]?
    let outputText: String?

    enum CodingKeys: String, CodingKey {
        case output
        case outputText = "output_text"
    }

    nonisolated struct Output: Decodable, Sendable {
        let content: [Content]?
    }

    nonisolated struct Content: Decodable, Sendable {
        let type: String
        let text: String?
    }

    var firstOutputText: String? {
        if let outputText, !outputText.isEmpty { return outputText }
        for item in output ?? [] {
            for c in item.content ?? [] where c.type.contains("text") {
                if let text = c.text { return text }
            }
        }
        return nil
    }
}

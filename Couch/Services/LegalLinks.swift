import Foundation

nonisolated struct LegalLinks: Sendable, Equatable {
    let privacyPolicy: URL
    let termsOfUse: URL

    static let privacyPolicyKey = "PRIVACY_POLICY_URL"
    static let termsOfUseKey = "TERMS_OF_USE_URL"

    static var current: LegalLinks {
        do {
            return try resolve()
        } catch {
            return LegalLinks(
                privacyPolicy: URL(string: "https://adamsardo.com/couch/privacy")!,
                termsOfUse: URL(string: "https://adamsardo.com/couch/terms")!
            )
        }
    }

    static func resolve(bundle: Bundle = .main) throws -> LegalLinks {
        try resolve(
            privacyRaw: bundle.object(forInfoDictionaryKey: privacyPolicyKey) as? String,
            termsRaw: bundle.object(forInfoDictionaryKey: termsOfUseKey) as? String
        )
    }

    static func resolve(privacyRaw: String?, termsRaw: String?) throws -> LegalLinks {
        LegalLinks(
            privacyPolicy: try validatedURL(privacyRaw, key: privacyPolicyKey),
            termsOfUse: try validatedURL(termsRaw, key: termsOfUseKey)
        )
    }

    private static func validatedURL(_ raw: String?, key: String) throws -> URL {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LegalLinksError.missing(key)
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              url.host != nil
        else {
            throw LegalLinksError.invalid(key)
        }
        if trimmed.lowercased().contains("example.com") {
            throw LegalLinksError.placeholder(key)
        }
        return url
    }
}

enum LegalLinksError: LocalizedError, Equatable {
    case missing(String)
    case invalid(String)
    case placeholder(String)

    var errorDescription: String? {
        switch self {
        case .missing(let key):
            return "Missing legal link: \(key)"
        case .invalid(let key):
            return "Invalid legal link: \(key)"
        case .placeholder(let key):
            return "Legal link still uses example.com: \(key)"
        }
    }
}

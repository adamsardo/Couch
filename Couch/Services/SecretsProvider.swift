import Foundation
import OSLog

/// Reads secret + configuration values for V1 (dev / TestFlight) from the
/// bundle's Info.plist or the process environment. The plist is sourced from
/// a gitignored `Secrets.plist` (or xcconfig-bridged build settings) — never
/// from a committed file.
///
/// This is the **only** location in the app that reads raw secrets. All
/// callers go through the typed accessors below (``elevenLabsAgentID`` etc.).
nonisolated final class SecretsProvider: Sendable {
    static let shared = SecretsProvider()

    /// `MARCUS_AGENT_ID` from Info.plist / env, or empty. Empty = the direct
    /// ElevenLabs transport will refuse to start (the LiveKit transport does
    /// not need this).
    func elevenLabsAgentID(forKey key: String) -> String {
        return string(forKey: key) ?? ""
    }

    /// ElevenLabs API key from Info.plist / env for private-agent token
    /// flows.
    func elevenLabsAPIKey() -> String? {
        return string(forKey: "ELEVENLABS_API_KEY")
    }

    /// OpenAI API key from current env / plist configuration, mirrored into
    /// Keychain so later launches can recover when no bundled value is present.
    func openAIAPIKey() -> String? {
        if let configured = configuredOpenAIAPIKey(), !configured.isEmpty {
            // Keep the cache fresh. A stale Keychain value previously won over
            // an updated Secrets.plist, which could leave local builds stuck on
            // OpenAI 401 even after the plist was corrected.
            if KeychainService.shared.read(account: KeychainAccount.openAI) != configured {
                KeychainService.shared.save(configured, account: KeychainAccount.openAI)
            }
            return configured
        }
        return KeychainService.shared.read(account: KeychainAccount.openAI)
    }

    /// Base URL of the Couch backend that mints LiveKit tokens (e.g.
    /// `https://couch.example.com`). Returns `nil` when unset; callers should
    /// refuse to start the LiveKit transport in that case.
    func couchBackendBaseURL() -> URL? {
        guard let raw = string(forKey: "COUCH_BACKEND_URL") else { return nil }
        return URL(string: raw)
    }

    /// Shared secret sent to the token endpoint as `X-Couch-Auth`. Rotatable
    /// independently of the app build.
    func couchBackendSharedSecret() -> String? {
        string(forKey: "COUCH_BACKEND_SHARED_SECRET")
    }

    /// Typed boolean reader used by feature flags.
    func boolValue(forKey key: String, default fallback: Bool) -> Bool {
        guard let raw = string(forKey: key) else { return fallback }
        switch raw.trimmingCharacters(in: .whitespaces).lowercased() {
        case "1", "true", "yes", "on": return true
        case "0", "false", "no", "off", "": return false
        default: return fallback
        }
    }

    private func string(forKey key: String) -> String? {
        if let env = ProcessInfo.processInfo.environment[key], !env.isEmpty {
            return env
        }
        if let secrets = bundledSecrets(), let value = secrets[key] as? String, !value.isEmpty {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty {
            return value
        }
        return nil
    }

    private func configuredOpenAIAPIKey() -> String? {
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        if let secrets = bundledSecrets(),
           let value = secrets["OPENAI_API_KEY"] as? String,
           !value.isEmpty {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !value.isEmpty {
            return value
        }
        return nil
    }

    private func bundledSecrets() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return nil
        }
        return plist
    }
}

enum KeychainAccount {
    nonisolated static let openAI = "openai-api-key"
}

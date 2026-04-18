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

    /// OpenAI API key from Keychain (preferred) or Info.plist / env (dev
    /// fallback).
    func openAIAPIKey() -> String? {
        if let stored = KeychainService.shared.read(account: KeychainAccount.openAI) {
            return stored
        }
        if let bundled = string(forKey: "OPENAI_API_KEY"), !bundled.isEmpty {
            // First-run migration: cache the bundled key into the keychain so
            // subsequent launches don't depend on a plist read.
            KeychainService.shared.save(bundled, account: KeychainAccount.openAI)
            return bundled
        }
        return nil
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
    static let openAI = "openai-api-key"
}

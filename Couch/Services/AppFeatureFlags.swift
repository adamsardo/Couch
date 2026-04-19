import Foundation

/// Simple launch-time feature flag set. Values are resolved once per run from
/// `Secrets.plist` / `Info.plist` / env, with safe defaults that keep the
/// legacy direct-ElevenLabs path on until operators explicitly opt in.
///
/// Everything the LiveKit + LemonSlice avatar path needs is guarded by
/// ``liveKitTransportEnabled`` so a bad day can be reverted without an App
/// Store release (PRD §6.1 / §8.3 / acceptance criterion "Operability").
nonisolated struct AppFeatureFlags: Sendable {
    /// Enables the LiveKit session driver + avatar stage. When false, the app
    /// keeps using the direct ElevenLabs SDK path as it did pre-avatars.
    let liveKitTransportEnabled: Bool

    /// Enables avatar stage rendering. Even when the transport is LiveKit, we
    /// can still run audio-only by disabling this flag.
    let avatarsEnabled: Bool

    /// Current launch-time flag set. Cached because these values are only
    /// meant to change across app launches.
    static let current: AppFeatureFlags = .resolved()

    private static func resolved() -> AppFeatureFlags {
        let provider = SecretsProvider.shared
        // Default OFF for the migration. Flip to ON once the backend is up.
        let livekit = provider.boolValue(
            forKey: FeatureFlagKeys.liveKitTransportEnabled,
            default: false
        )
        let avatars = provider.boolValue(
            forKey: FeatureFlagKeys.avatarsEnabled,
            default: livekit
        )
        return AppFeatureFlags(
            liveKitTransportEnabled: livekit,
            avatarsEnabled: avatars
        )
    }
}

enum FeatureFlagKeys {
    static let liveKitTransportEnabled = "COUCH_LIVEKIT_ENABLED"
    static let avatarsEnabled = "COUCH_AVATARS_ENABLED"
}

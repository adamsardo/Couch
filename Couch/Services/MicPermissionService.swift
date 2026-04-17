import AVFoundation
import Foundation

enum MicPermissionStatus: Sendable {
    case undetermined
    case granted
    case denied
}

/// Thin wrapper around `AVAudioApplication` for the mic permission flow.
@MainActor
final class MicPermissionService {
    static let shared = MicPermissionService()

    var current: MicPermissionStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        case .undetermined: return .undetermined
        @unknown default: return .undetermined
        }
    }

    /// Triggers the system permission prompt if not yet determined.
    /// Returns the resolved permission state.
    func request() async -> MicPermissionStatus {
        if current != .undetermined { return current }
        let granted = await AVAudioApplication.requestRecordPermission()
        return granted ? .granted : .denied
    }
}

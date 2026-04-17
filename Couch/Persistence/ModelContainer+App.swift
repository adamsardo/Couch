import Foundation
import SwiftData
import OSLog

/// Builds the app-wide SwiftData container, including seed data on first launch.
enum AppModelContainer {
    static let schema = Schema([
        UserProfile.self,
        Scenario.self,
        Session.self,
        Turn.self,
        Debrief.self,
        MicroDrill.self,
        StreakEvent.self
    ])

    static func make() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            SeedData.runIfNeeded(container: container)
            return container
        } catch {
            Logger.couch.error("Failed to create ModelContainer: \(error.localizedDescription, privacy: .public)")
            // Last-resort fallback so the app still launches in a recoverable state during development.
            // swiftlint:disable:next force_try
            return try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
    }

    /// In-memory container for SwiftUI previews and tests.
    static func previewContainer(seeded: Bool = true) -> ModelContainer {
        do {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if seeded {
                SeedData.runIfNeeded(container: container)
            }
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}

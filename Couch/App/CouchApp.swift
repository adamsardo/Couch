import SwiftData
import SwiftUI

@main
struct CouchApp: App {
    private let modelContainer: ModelContainer = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .modelContainer(modelContainer)
                .tint(CouchTheme.primary)
                .background(CouchTheme.background.ignoresSafeArea())
                .preferredColorScheme(.light)
        }
    }
}

import SwiftData
import SwiftUI

@main
struct CouchApp: App {
    private let modelContainer: ModelContainer = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            SplashHost {
                AppRoot()
            }
            .modelContainer(modelContainer)
            .tint(CouchTheme.primary)
            .background(CouchTheme.background.ignoresSafeArea())
        }
    }
}

/// Shows a branded splash for a short minimum duration, then cross-fades to
/// the app's real content. The host keeps the splash alive across the
/// content's first layout pass so the handover feels intentional rather
/// than abrupt.
private struct SplashHost<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var showContent = false

    var body: some View {
        ZStack {
            content()
                .opacity(showContent ? 1 : 0)
                .allowsHitTesting(showContent)

            if !showContent {
                SplashView {
                    withAnimation(.easeInOut(duration: CouchMotion.state)) {
                        showContent = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

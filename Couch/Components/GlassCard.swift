import SwiftUI

/// Branded container card that handles its own padding, shape and shadow via `CouchGlassCardStyle`.
struct GlassCard<Content: View>: View {
    var tint: Color? = nil
    var radius: CGFloat = CouchTheme.Radius.card
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .couchGlassCard(radius: radius, tint: tint)
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today’s suggested rep")
                    .font(CouchTheme.Typography.cardTitle)
                Text("Marcus, 28 — first session intake")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
            }
        }
        GlassCard(tint: CouchTheme.accent.opacity(0.18)) {
            Text("Tinted variant")
                .font(CouchTheme.Typography.body)
        }
    }
    .padding()
    .background(CouchTheme.background)
}

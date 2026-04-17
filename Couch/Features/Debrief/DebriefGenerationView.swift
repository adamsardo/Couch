import SwiftUI

struct DebriefGenerationView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: CouchTheme.Spacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(CouchTheme.accent.opacity(0.18))
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulse ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(CouchTheme.accent)
            }
            VStack(spacing: 8) {
                Text("Reading your rep…")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)
                Text("Looking for what landed and what to sharpen.")
                    .font(CouchTheme.Typography.body)
                    .foregroundStyle(CouchTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CouchTheme.Spacing.lg)
            }
            ProgressView()
                .controlSize(.regular)
                .tint(CouchTheme.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CouchTheme.background)
        .onAppear { pulse = true }
    }
}

#Preview { DebriefGenerationView() }

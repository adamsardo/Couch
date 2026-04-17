import SwiftUI

struct SessionIntroView: View {
    let scenario: Scenario
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            hero
                .frame(height: 360)

            VStack(alignment: .leading, spacing: CouchTheme.Spacing.md) {
                Text("First rep \u{2014} Session 1 with \(scenario.patientName)")
                    .font(CouchTheme.Typography.title)
                    .foregroundStyle(CouchTheme.textPrimary)

                VStack(spacing: CouchTheme.Spacing.sm) {
                    infoRow(icon: "clock", title: "Duration", value: "~10 minutes")
                    infoRow(icon: "target", title: "Main goal", value: "Stay curious, not certain")
                    infoRow(icon: "flag.checkered", title: "Outcome", value: "Debrief with 3 next moves")
                }

                Spacer()

                SecondaryButton(title: "Plan conversation", systemImage: "clock") {}
                PrimaryButton(title: "Start conversation", systemImage: "play.fill") {
                    onStart()
                }
            }
            .padding(CouchTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: CouchTheme.Radius.sheet,
                    topTrailingRadius: CouchTheme.Radius.sheet
                )
                .fill(CouchTheme.background)
                .ignoresSafeArea(edges: .bottom)
            )
            .offset(y: -CouchTheme.Radius.sheet)
        }
        .background(Color.black)
    }

    @ViewBuilder
    private var hero: some View {
        let assetName = "scenario-\(scenario.id)"
        ZStack {
            if UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [CouchTheme.callSurfaceMuted, CouchTheme.callSurface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Text(String(scenario.patientName.prefix(1)))
                        .font(.system(size: 160, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: CouchTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.footnote.weight(.bold))
                .foregroundStyle(CouchTheme.textPrimary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(CouchTheme.surfaceMuted))

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(CouchTheme.Typography.caption)
                    .foregroundStyle(CouchTheme.textMuted)
                Text(value)
                    .font(CouchTheme.Typography.bodyEmphasized)
                    .foregroundStyle(CouchTheme.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, CouchTheme.Spacing.md)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: CouchTheme.Radius.option, style: .continuous)
                .strokeBorder(CouchTheme.divider, lineWidth: 1)
        )
    }
}

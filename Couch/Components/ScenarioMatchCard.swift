import SwiftUI

/// A portrait-led virtual patient card used on the scenario match carousel.
/// Selected state uses the deep-violet brand border and checkmark badge.
struct ScenarioMatchCard: View {
    enum Fit: Equatable {
        case best
        case good
        case comingSoon
    }

    let name: String
    let quote: String
    let fit: Fit
    let portraitAsset: String?
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            CouchHaptics.tap()
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: CouchTheme.Spacing.sm) {
                portrait
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(CouchTheme.Typography.cardTitle)
                        .foregroundStyle(CouchTheme.textPrimary)
                    Text(fitLabel)
                        .font(CouchTheme.Typography.bodyEmphasized)
                        .foregroundStyle(fitColor)
                    Text("\u{201C}\(quote)\u{201D}")
                        .font(CouchTheme.Typography.caption)
                        .foregroundStyle(CouchTheme.textSecondary)
                        .italic()
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(.couchPress)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var portrait: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: CouchTheme.Radius.card, style: .continuous)
                .fill(CouchTheme.surfaceMuted)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay(
                    Group {
                        if let portraitAsset, UIImage(named: portraitAsset) != nil {
                            Image(portraitAsset)
                                .resizable()
                                .scaledToFill()
                        } else {
                            monogram
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: CouchTheme.Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CouchTheme.Radius.card, style: .continuous)
                        .strokeBorder(isSelected ? CouchTheme.primary : Color.clear, lineWidth: 3)
                )
                .opacity(fit == .comingSoon ? 0.5 : 1)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(CouchTheme.primary))
                    .padding(10)
            }
        }
    }

    private var monogram: some View {
        ZStack {
            LinearGradient(
                colors: [CouchTheme.surfaceMuted, CouchTheme.primarySoft.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            Text(name.prefix(1).uppercased())
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(CouchTheme.textPrimary.opacity(0.25))
        }
    }

    private var fitLabel: String {
        switch fit {
        case .best: return "Best first rep"
        case .good: return "Available"
        case .comingSoon: return "Coming soon"
        }
    }

    private var fitColor: Color {
        switch fit {
        case .best: return CouchTheme.primary
        case .good: return CouchTheme.textMuted
        case .comingSoon: return CouchTheme.textMuted
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ScenarioMatchCard(
            name: "Marcus",
            quote: "Stay curious, not certain.",
            fit: .best,
            portraitAsset: nil,
            isSelected: true,
            onTap: {}
        )
        ScenarioMatchCard(
            name: "Aisha",
            quote: "Help me stop spiralling.",
            fit: .good,
            portraitAsset: nil
        )
    }
    .padding()
    .background(CouchTheme.background)
}

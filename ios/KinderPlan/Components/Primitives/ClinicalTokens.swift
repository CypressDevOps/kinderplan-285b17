// 10x primitive: cal-ai/design-tokens v1
import SwiftUI

/// Central design tokens for the clinical cal-ai language. The app's whole
/// theme lives here: retheme by editing these values, add new tokens here,
/// and never hardcode colors or fonts in views.
///
/// Values are the observed palette from REFERENCE.md: strictly monochrome
/// structure (near-black ink doubling as the accent, white cards on a warm
/// off-white ground) plus a muted three-color data trio and small green/red
/// semantic accents. Type is the standard system grotesque with monospaced
/// digits — numbers do the shouting.
@available(iOS 17.0, *)
public enum ClinicalTokens {
    // MARK: Grounds & surfaces
    /// Warm off-white screen background behind cards (~#F7F5F2).
    public static let ground = Color(red: 0.969, green: 0.961, blue: 0.949)
    /// Card and sheet surface — every card in the reference is plain white.
    public static let surface = Color.white
    /// Raised tiles/sheets. Same white as `surface`; elevation comes from the
    /// set's soft 0.06-opacity shadow, never from a darker fill.
    public static let surfaceRaised = Color.white
    /// Hairline tracks, dividers, and thin chart gridlines (~#ECECEC).
    public static let hairline = Color(red: 0.925, green: 0.925, blue: 0.925)

    // MARK: Ink
    /// Primary text and the brand ink (~#1A1A1A).
    public static let ink = Color(red: 0.102, green: 0.102, blue: 0.102)
    /// Captions, axis labels, secondary values (~#8A8A8E).
    public static let inkSecondary = Color(red: 0.541, green: 0.541, blue: 0.557)
    /// Label color on accent-filled controls (white on the black CTA).
    public static let inkOnAccent = Color.white

    // MARK: Accent & semantics
    /// The brand accent IS the ink: black rings, black CTAs, black FAB.
    public static let accent = Color(red: 0.102, green: 0.102, blue: 0.102)
    /// Accent at 12% for selection fills and tinted chips.
    public static let accentSoft = Color(red: 0.102, green: 0.102, blue: 0.102).opacity(0.12)
    /// Positive delta green (~#34C759-class, observed on week-over-week chips).
    public static let positive = Color(red: 0.204, green: 0.780, blue: 0.349)
    /// Over-target / error red (system-red class, observed on the over-target pulse).
    public static let negative = Color(red: 0.898, green: 0.282, blue: 0.302)
    /// Amber for caution and rising-trend chips (~#E8A05A-class).
    public static let warning = Color(red: 0.910, green: 0.627, blue: 0.353)

    // MARK: Data colors (the observed muted macro trio)
    /// Muted salmon (~#E36A6A) — first data series (protein in the reference).
    public static let dataRose = Color(red: 0.890, green: 0.416, blue: 0.416)
    /// Muted tan (~#E8A05A) — second data series (carbs in the reference).
    public static let dataAmber = Color(red: 0.910, green: 0.627, blue: 0.353)
    /// Muted periwinkle (~#6C8FE0) — third data series (fats in the reference).
    public static let dataAzure = Color(red: 0.424, green: 0.561, blue: 0.878)

    // MARK: Radii
    /// Working card radius (log cards, plan cards, option rows).
    public static let radiusCard: CGFloat = 16
    /// Inner elements: thumbnails, small containers.
    public static let radiusControl: CGFloat = 12
    /// Large sheet / tile radius (sheet tops, stat tiles use `radiusTile`).
    public static let radiusSheet: CGFloat = 28
    /// Stat tiles and section cards.
    public static let radiusTile: CGFloat = 20

    // MARK: Type
    /// Hero numerals — bold system grotesque with tabular digits.
    public static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold).monospacedDigit()
    }
    public static let titleFont: Font = .system(.title, weight: .bold)
    public static let headlineFont: Font = .system(.headline, weight: .semibold)
    public static let bodyFont: Font = .system(.body)
    public static let captionFont: Font = .system(.footnote)
}

#Preview("Token swatches") {
    if #available(iOS 17.0, *) {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("cal-ai tokens").font(ClinicalTokens.titleFont)
                ForEach(
                    [("ground", ClinicalTokens.ground), ("surface", ClinicalTokens.surface),
                     ("hairline", ClinicalTokens.hairline), ("ink", ClinicalTokens.ink),
                     ("inkSecondary", ClinicalTokens.inkSecondary), ("accent", ClinicalTokens.accent),
                     ("positive", ClinicalTokens.positive), ("negative", ClinicalTokens.negative),
                     ("warning", ClinicalTokens.warning), ("dataRose", ClinicalTokens.dataRose),
                     ("dataAmber", ClinicalTokens.dataAmber), ("dataAzure", ClinicalTokens.dataAzure)],
                    id: \.0
                ) { name, color in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(width: 44, height: 28)
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(ClinicalTokens.hairline))
                        Text(name).font(ClinicalTokens.bodyFont).foregroundStyle(ClinicalTokens.ink)
                    }
                }
                Text("1,850").font(ClinicalTokens.display(44)).foregroundStyle(ClinicalTokens.ink)
                Text("Numbers do the shouting")
                    .font(ClinicalTokens.captionFont)
                    .foregroundStyle(ClinicalTokens.inkSecondary)
            }
            .padding(20)
        }
        .background(ClinicalTokens.ground)
    }
}

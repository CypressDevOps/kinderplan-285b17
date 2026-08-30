import SwiftUI

/// Zentrale Design-Tokens für KinderPlan basierend auf dem Clinical-Minimal (cal-ai) Designstil
/// mit der Palette 'Ruhiges Petrol' (#2C5B5C, #3E8384).
public enum AppTheme {
    // MARK: - Core Colors
    public static let primary = Color(red: 0.173, green: 0.357, blue: 0.361)      // #2C5B5C
    public static let accent = Color(red: 0.243, green: 0.514, blue: 0.518)       // #3E8384
    public static let background = Color(red: 0.984, green: 0.984, blue: 0.984)   // #FBFBFB
    public static let surface = Color(red: 1.0, green: 1.0, blue: 1.0)            // #FFFFFF
    public static let surfaceSecondary = Color(red: 0.95, green: 0.96, blue: 0.96)
    public static let text = Color(red: 0.078, green: 0.125, blue: 0.122)          // #14201F
    public static let textSecondary = Color(red: 0.40, green: 0.46, blue: 0.46)
    public static let border = Color(red: 0.88, green: 0.90, blue: 0.90)

    // MARK: - Parent Visual Identity (Ruhig, dezent, barrierearm mit Text & Symbol)
    public static let parentAColor = Color(red: 0.20, green: 0.45, blue: 0.55)    // Ruhiges Schieferblau
    public static let parentABackground = Color(red: 0.90, green: 0.94, blue: 0.97)
    public static let parentBColor = Color(red: 0.62, green: 0.40, blue: 0.32)    // Ruhiges Terracotta/Warmbraun
    public static let parentBBackground = Color(red: 0.97, green: 0.93, blue: 0.91)
    
    public static let neutralColor = Color(red: 0.50, green: 0.53, blue: 0.53)
    public static let neutralBackground = Color(red: 0.94, green: 0.94, blue: 0.94)

    // MARK: - Semantic States
    public static let exceptionAccent = Color(red: 0.85, green: 0.48, blue: 0.20) // Dezentes Bernstein für Ausnahmen
    public static let exceptionBackground = Color(red: 0.99, green: 0.95, blue: 0.90)
    public static let transitionAccent = Color(red: 0.24, green: 0.51, blue: 0.52)
    public static let transitionBackground = Color(red: 0.91, green: 0.96, blue: 0.96)

    // MARK: - Spacing Grid (4pt Basis)
    public static let spaceXXS: CGFloat = 4
    public static let spaceXS: CGFloat = 8
    public static let spaceSM: CGFloat = 12
    public static let spaceMD: CGFloat = 16
    public static let spaceLG: CGFloat = 20
    public static let spaceXL: CGFloat = 24
    public static let spaceXXL: CGFloat = 32
    public static let spaceHuge: CGFloat = 48
    public static let screenMargin: CGFloat = 16

    // MARK: - Corner Radii
    public static let radiusCard: CGFloat = 14
    public static let radiusButton: CGFloat = 12
    public static let radiusBadge: CGFloat = 8
    public static let radiusSmall: CGFloat = 6

    // MARK: - Typography Ramp
    public static let displayHero = Font.system(size: 34, weight: .bold, design: .default)
    public static let title1 = Font.system(size: 26, weight: .bold, design: .default)
    public static let title2 = Font.system(size: 20, weight: .bold, design: .default)
    public static let title3 = Font.system(size: 17, weight: .semibold, design: .default)
    public static let headline = Font.system(size: 16, weight: .semibold, design: .default)
    public static let body = Font.system(size: 16, weight: .regular, design: .default)
    public static let subheadline = Font.system(size: 14, weight: .regular, design: .default)
    public static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    public static let caption = Font.system(size: 12, weight: .medium, design: .default)
    public static let eyebrow = Font.system(size: 11, weight: .bold, design: .default)
}

public struct PrimaryCapsuleButtonStyle: ButtonStyle {
    public var isDestructive: Bool = false
    
    public init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline)
            .foregroundStyle(Color.white)
            .padding(.vertical, 14)
            .padding(.horizontal, AppTheme.spaceLG)
            .frame(maxWidth: .infinity)
            .background(
                isDestructive ? Color.red : AppTheme.accent
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct SecondaryCapsuleButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline)
            .foregroundStyle(AppTheme.text)
            .padding(.vertical, 14)
            .padding(.horizontal, AppTheme.spaceLG)
            .frame(maxWidth: .infinity)
            .background(AppTheme.surfaceSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(AppTheme.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

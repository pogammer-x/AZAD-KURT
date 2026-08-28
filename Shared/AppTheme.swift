import SwiftUI

enum AppTheme {
    // Corporate palette: #0D0D0D, #1E1E1E, #B11226, #FFFFFF, #2A2A2A.
    static let background = Color(red: 13.0 / 255.0, green: 13.0 / 255.0, blue: 13.0 / 255.0)
    static let sidebar = Color.black
    static let panel = Color(red: 30.0 / 255.0, green: 30.0 / 255.0, blue: 30.0 / 255.0)
    static let card = panel
    static let cardSecondary = Color(red: 42.0 / 255.0, green: 42.0 / 255.0, blue: 42.0 / 255.0)
    static let cardElevated = cardSecondary
    static let border = Color.white.opacity(0.10)
    static let accent = Color(red: 177.0 / 255.0, green: 18.0 / 255.0, blue: 38.0 / 255.0)
    static let accentMuted = accent.opacity(0.18)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)
    static let primaryText = textPrimary
    static let secondaryText = textSecondary
    static let positive = Color(red: 0.20, green: 0.72, blue: 0.40)
    static let warning = Color(red: 0.95, green: 0.58, blue: 0.16)
    static let negative = accent
}

struct PremiumCardModifier: ViewModifier {
    var secondary: Bool

    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(secondary ? AppTheme.cardSecondary : AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct AccentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.accent))
    }
}

struct CorporateScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(AppTheme.primaryText)
            .accentColor(AppTheme.accent)
            .background(AppTheme.background)
    }
}

extension View {
    func corporateScreen() -> some View {
        modifier(CorporateScreenModifier())
    }

    func premiumCard(secondary: Bool = false) -> some View {
        modifier(PremiumCardModifier(secondary: secondary))
    }

    func accentButton() -> some View {
        modifier(AccentButtonModifier())
    }
}

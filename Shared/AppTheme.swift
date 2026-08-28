import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.035, green: 0.035, blue: 0.040)
    static let sidebar = Color(red: 0.055, green: 0.055, blue: 0.062)
    static let panel = Color(red: 0.070, green: 0.070, blue: 0.078)
    static let card = Color(red: 0.085, green: 0.085, blue: 0.095)
    static let cardElevated = Color(red: 0.105, green: 0.105, blue: 0.115)
    static let border = Color.white.opacity(0.10)
    static let accent = Color(red: 0.82, green: 0.055, blue: 0.075)
    static let accentMuted = accent.opacity(0.18)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.62)
    static let positive = Color(red: 0.20, green: 0.72, blue: 0.40)
    static let warning = Color(red: 0.95, green: 0.58, blue: 0.16)
    static let negative = accent
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
}

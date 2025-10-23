import SwiftUI
import Foundation

// MARK: - Modern Design System
struct AppTheme: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let primaryHex: String // Background color
    let accentHex: String // Logo text and accent color
    let secondaryHex: String // Secondary background color
    let cardHex: String // Card background color
    let textPrimaryHex: String // Primary text color
    let textSecondaryHex: String // Secondary text color
    let successHex: String // Success color
    let warningHex: String // Warning color
    let errorHex: String // Error color
    
    var primary: Color {
        Color(hex: primaryHex)
    }
    
    var accent: Color {
        Color(hex: accentHex)
    }
    
    var secondary: Color {
        Color(hex: secondaryHex)
    }
    
    var cardBackground: Color {
        Color(hex: cardHex)
    }
    
    var textPrimary: Color {
        Color(hex: textPrimaryHex)
    }
    
    var textSecondary: Color {
        Color(hex: textSecondaryHex)
    }
    
    var success: Color {
        Color(hex: successHex)
    }
    
    var warning: Color {
        Color(hex: warningHex)
    }
    
    var error: Color {
        Color(hex: errorHex)
    }
    
    init(name: String, primaryHex: String, accentHex: String, secondaryHex: String, cardHex: String, textPrimaryHex: String, textSecondaryHex: String, successHex: String, warningHex: String, errorHex: String) {
        self.name = name
        self.primaryHex = primaryHex
        self.accentHex = accentHex
        self.secondaryHex = secondaryHex
        self.cardHex = cardHex
        self.textPrimaryHex = textPrimaryHex
        self.textSecondaryHex = textSecondaryHex
        self.successHex = successHex
        self.warningHex = warningHex
        self.errorHex = errorHex
    }
    
    static let themes: [AppTheme] = [
        // Light
        AppTheme(
            name: "Light",
            primaryHex: "#f5f5f7",
            accentHex: "#0076f7",
            secondaryHex: "#e8e8ed",
            cardHex: "#ffffff",
            textPrimaryHex: "#1d1d1f",
            textSecondaryHex: "#86868b",
            successHex: "#30d158",
            warningHex: "#ff9500",
            errorHex: "#ff3b30"
        ),
        // Dark
        AppTheme(
            name: "Dark",
            primaryHex: "#000000",
            accentHex: "#0076f7",
            secondaryHex: "#1c1c1e",
            cardHex: "#2c2c2e",
            textPrimaryHex: "#ffffff",
            textSecondaryHex: "#98989d",
            successHex: "#30d158",
            warningHex: "#ff9500",
            errorHex: "#ff3b30"
        )
    ]
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Placeholder utility for TextField/SecureField
extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder _ placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Modern UI Components
struct ModernCard<Content: View>: View {
    let content: Content
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(themeManager.selectedTheme.cardBackground)
        .cornerRadius(16)
        .shadow(
            color: themeManager.selectedTheme.textPrimary.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

struct ModernButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    @EnvironmentObject private var themeManager: ThemeManager
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(backgroundColor)
                .cornerRadius(12)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return themeManager.selectedTheme.accent
        case .secondary:
            return themeManager.selectedTheme.secondary
        case .destructive:
            return themeManager.selectedTheme.error
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return themeManager.selectedTheme.textPrimary
        }
    }
}

struct ModernTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .placeholder(when: text.isEmpty) {
            Text(placeholder)
                .foregroundColor(themeManager.selectedTheme.textSecondary)
        }
        .padding()
        .background(themeManager.selectedTheme.secondary)
        .cornerRadius(12)
        .foregroundColor(themeManager.selectedTheme.textPrimary)
        .tint(themeManager.selectedTheme.accent)
    }
}

struct GradientBackground: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                themeManager.selectedTheme.primary,
                themeManager.selectedTheme.secondary
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Theme Manager
enum ThemeChoice: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
}

class ThemeManager: ObservableObject {
    @Published private(set) var choice: ThemeChoice {
        didSet { saveChoice() }
    }
    
    let themes: [AppTheme] = AppTheme.themes
    
    init() {
        self.choice = .system
        loadChoice()
    }
    
    func setChoice(_ newChoice: ThemeChoice) {
        choice = newChoice
    }
    
    var selectedTheme: AppTheme {
        switch choice {
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark ? Self.themes[1] : Self.themes[0]
        case .light:
            return Self.themes[0]
        case .dark:
            return Self.themes[1]
        }
    }
    
    private static let themes: [AppTheme] = AppTheme.themes
    
    private func saveChoice() {
        UserDefaults.standard.set(choice.rawValue, forKey: "themeChoice")
    }
    
    private func loadChoice() {
        if let raw = UserDefaults.standard.string(forKey: "themeChoice"),
           let c = ThemeChoice(rawValue: raw) {
            self.choice = c
        }
    }
}


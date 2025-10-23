import SwiftUI
import UIKit

// MARK: - Color System Utilities
struct ColorSystem {
    
    // MARK: - System Colors
    static let systemBlue = Color.blue
    static let systemGreen = Color.green
    static let systemRed = Color.red
    static let systemOrange = Color.orange
    static let systemPurple = Color.purple
    static let systemPink = Color.pink
    static let systemYellow = Color.yellow
    static let systemIndigo = Color.indigo
    static let systemTeal = Color.teal
    static let systemCyan = Color.cyan
    static let systemMint = Color.mint
    
    // MARK: - Semantic Colors
    static let primary = Color.primary
    static let secondary = Color.secondary
    static let tertiary = Color(UIColor.tertiaryLabel)
    static let quaternary = Color(UIColor.quaternaryLabel)
    
    // MARK: - Background Colors
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Grouped Background Colors
    static let groupedBackground = Color(UIColor.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let tertiaryGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)
    
    // MARK: - Fill Colors
    static let fill = Color(UIColor.systemFill)
    static let secondaryFill = Color(UIColor.secondarySystemFill)
    static let tertiaryFill = Color(UIColor.tertiarySystemFill)
    static let quaternaryFill = Color(UIColor.quaternarySystemFill)
    
    // MARK: - Separator Colors
    static let separator = Color(UIColor.separator)
    static let opaqueSeparator = Color(UIColor.opaqueSeparator)
    
    // MARK: - Link Colors
    static let link = Color(UIColor.link)
    static let placeholderText = Color(UIColor.placeholderText)
    
    // MARK: - Custom Color Extensions
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            case .light, .unspecified:
                return UIColor(light)
            @unknown default:
                return UIColor(light)
            }
        })
    }
    
    // MARK: - Gradient Utilities
    static func createGradient(colors: [Color], startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    static func createRadialGradient(colors: [Color], center: UnitPoint = .center, startRadius: CGFloat = 0, endRadius: CGFloat = 1) -> RadialGradient {
        return RadialGradient(
            gradient: Gradient(colors: colors),
            center: center,
            startRadius: startRadius,
            endRadius: endRadius
        )
    }
    
    // MARK: - Color Opacity Utilities
    static func withOpacity(_ color: Color, _ opacity: Double) -> Color {
        return color.opacity(opacity)
    }
    
    // MARK: - Accessibility Colors
    static let accessibilityFocus = Color(UIColor.systemBlue)
    static let accessibilitySelected = Color(UIColor.systemBlue)
    static let accessibilityHighlighted = Color(UIColor.systemBlue)
}

// MARK: - Color Extensions
extension Color {
    
    /// Creates a color with the specified opacity
    func withAlpha(_ alpha: Double) -> Color {
        return self.opacity(alpha)
    }
    
    /// Creates a lighter version of the color
    func lighter(by percentage: Double = 0.1) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    /// Creates a darker version of the color
    func darker(by percentage: Double = 0.1) -> Color {
        return self.opacity(1.0 + percentage)
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    
    /// Creates a UIColor from a hex string
    convenience init(hex: String) {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

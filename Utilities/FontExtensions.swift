import SwiftUI

extension Font {
    static func tanTangkiwood(size: CGFloat) -> Font {
        // Try multiple font name variations without verbose logging
        let fontNames = [
            "TANTangkiwood-Display",
            "TAN- Tangkiwood",
            "TAN- Tangkiwood Display",
            "TANTangkiwoodDisplay",
            "Tangkiwood-Display",
            "Tangkiwood"
        ]
        
        for fontName in fontNames {
            if let font = UIFont(name: fontName, size: size) {
                return Font(font)
            }
        }
        
        // Fallback to system font if custom font is not available
        return .system(size: size, weight: .bold, design: .rounded)
    }
}

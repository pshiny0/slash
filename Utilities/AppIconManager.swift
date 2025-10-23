import SwiftUI
import UIKit

// MARK: - App Icon Manager
class AppIconManager: ObservableObject {
    @Published var currentIcon: AppIcon = .blackWhiteOutlineMonogram
    
    init() {
        print("AppIconManager initialized")
        print("Supports alternate icons: \(UIApplication.shared.supportsAlternateIcons)")
        print("Current alternate icon: \(UIApplication.shared.alternateIconName ?? "none")")
        
        // Check if we're in development mode
        #if DEBUG
        print("⚠️ Running in DEBUG mode - alternate icons may not work properly in simulator")
        print("💡 Try running on a physical device for best results")
        #endif
        
        loadCurrentIcon()
    }
    
    func setIcon(_ icon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("App doesn't support alternate icons")
            return
        }
        
        // Always use the rawValue for alternate icons
        let iconName = icon.rawValue
        
        print("Setting app icon to: \(iconName)")
        print("Current alternate icon before change: \(UIApplication.shared.alternateIconName ?? "none")")
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Failed to set app icon: \(error)")
                print("Error details: \(error.localizedDescription)")
            } else {
                print("Successfully set app icon to: \(iconName)")
                print("Current alternate icon after change: \(UIApplication.shared.alternateIconName ?? "none")")
                
                DispatchQueue.main.async {
                    self.currentIcon = icon
                    self.saveCurrentIcon()
                    
                    // Force a small delay and then check if the icon actually changed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let currentIconName = UIApplication.shared.alternateIconName
                        print("Final verification - current icon: \(currentIconName ?? "none")")
                        
                        if currentIconName == iconName {
                            print("✅ Icon change confirmed by system")
                        } else {
                            print("⚠️ Icon change not confirmed by system")
                        }
                        
                        // Show user instruction to restart app
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootViewController = window.rootViewController {
                                
                                // Check if there's already a presented view controller
                                if rootViewController.presentedViewController == nil {
                                    let alert = UIAlertController(
                                        title: "App Icon Changed",
                                        message: "The app icon has been changed successfully. To see the new icon on your home screen, please:\n\n1. Close this app completely\n2. Go to your home screen\n3. The new icon should appear\n\nNote: Sometimes you may need to restart your device for the icon to update.",
                                        preferredStyle: .alert
                                    )
                                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                                    rootViewController.present(alert, animated: true)
                                } else {
                                    print("⚠️ Cannot show alert - another view controller is already being presented")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loadCurrentIcon() {
        if let iconName = UIApplication.shared.alternateIconName,
           let icon = AppIcon(rawValue: iconName) {
            currentIcon = icon
            print("Loaded current icon: \(iconName)")
        } else {
            // No alternate icon is set, so we're using the default
            currentIcon = .blackWhiteOutlineMonogram
            print("Using default icon: black-white-outline-monogram")
        }
    }
    
    private func saveCurrentIcon() {
        UserDefaults.standard.set(currentIcon.rawValue, forKey: "selectedAppIcon")
    }
}

// MARK: - App Icon Enum
enum AppIcon: String, CaseIterable, Identifiable {
    case blackWhiteOutlineMonogram = "black-white-outline-monogram"
    case blackWhiteSolidMonogram = "black-white-solid-monogram"
    case blackWhiteTitle = "black-white-title"
    case blueWhiteOutlineMonogram = "blue-white-outline-monogram"
    case blueWhiteSolidMonogram = "blue-white-solid-monogram"
    case blueWhiteTitle = "blue-white-title"
    case whiteBlackSolidMonogram = "white-black-solid-monogram"
    case whiteBlackTitle = "white-black-title"
    case whiteBlueSolidMonogram = "white-blue-solid-monogram"
    case whiteBlueTitle = "white-blue-title"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blackWhiteOutlineMonogram:
            return "Black White Outline"
        case .blackWhiteSolidMonogram:
            return "Black White Solid"
        case .blackWhiteTitle:
            return "Black White Title"
        case .blueWhiteOutlineMonogram:
            return "Blue White Outline"
        case .blueWhiteSolidMonogram:
            return "Blue White Solid"
        case .blueWhiteTitle:
            return "Blue White Title"
        case .whiteBlackSolidMonogram:
            return "White Black Solid"
        case .whiteBlackTitle:
            return "White Black Title"
        case .whiteBlueSolidMonogram:
            return "White Blue Solid"
        case .whiteBlueTitle:
            return "White Blue Title"
        }
    }
    
    var description: String {
        switch self {
        case .blackWhiteOutlineMonogram:
            return "Black and white outline monogram design"
        case .blackWhiteSolidMonogram:
            return "Black and white solid monogram design"
        case .blackWhiteTitle:
            return "Black and white with title text"
        case .blueWhiteOutlineMonogram:
            return "Blue and white outline monogram design"
        case .blueWhiteSolidMonogram:
            return "Blue and white solid monogram design"
        case .blueWhiteTitle:
            return "Blue and white with title text"
        case .whiteBlackSolidMonogram:
            return "White and black solid monogram design"
        case .whiteBlackTitle:
            return "White and black with title text"
        case .whiteBlueSolidMonogram:
            return "White and blue solid monogram design"
        case .whiteBlueTitle:
            return "White and blue with title text"
        }
    }
    
    var previewColor: Color {
        switch self {
        case .blackWhiteOutlineMonogram, .blackWhiteSolidMonogram, .blackWhiteTitle:
            return .black
        case .blueWhiteOutlineMonogram, .blueWhiteSolidMonogram, .blueWhiteTitle, .whiteBlueSolidMonogram, .whiteBlueTitle:
            return .blue
        case .whiteBlackSolidMonogram, .whiteBlackTitle:
            return .white
        }
    }
}

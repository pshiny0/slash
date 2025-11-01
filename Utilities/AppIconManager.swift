import SwiftUI
import UIKit

// MARK: - App Icon Manager
class AppIconManager: ObservableObject {
    @Published var currentIcon: AppIcon = .blueprint
    
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
        
        // Use the rawValue for alternate icons, or nil for the default icon
        let iconName = icon == .blueprint ? nil : icon.rawValue
        
        print("Setting app icon to: \(iconName ?? "blueprint (default)")")
        print("Current alternate icon before change: \(UIApplication.shared.alternateIconName ?? "none")")
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Failed to set app icon: \(error)")
                print("Error details: \(error.localizedDescription)")
            } else {
                print("Successfully set app icon to: \(iconName ?? "blueprint (default)")")
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
            currentIcon = .blueprint
            print("Using default icon: blueprint")
        }
    }
    
    private func saveCurrentIcon() {
        UserDefaults.standard.set(currentIcon.rawValue, forKey: "selectedAppIcon")
    }
}

// MARK: - App Icon Enum
enum AppIcon: String, CaseIterable, Identifiable {
    case blueprint = "blueprint"
    case blueprintEcho = "blueprint-echo"
    case graphite = "graphite"
    case graphiteEcho = "graphite-echo"
    case lumenBlack = "lumen-black"
    case lumenBlue = "lumen-blue"
    case studioBlack = "studio-black"
    case studioBlue = "studio-blue"
    case wireframeBlack = "wireframe-black"
    case wireframeBlue = "wireframe-blue"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blueprint:
            return "Blueprint"
        case .blueprintEcho:
            return "Blueprint Echo"
        case .graphite:
            return "Graphite"
        case .graphiteEcho:
            return "Graphite Echo"
        case .lumenBlack:
            return "Lumen Black"
        case .lumenBlue:
            return "Lumen Blue"
        case .studioBlack:
            return "Studio Black"
        case .studioBlue:
            return "Studio Blue"
        case .wireframeBlack:
            return "Wireframe Black"
        case .wireframeBlue:
            return "Wireframe Blue"
        }
    }
    
    var description: String {
        switch self {
        case .blueprint:
            return "Clean blueprint design"
        case .blueprintEcho:
            return "Blueprint design with echo effect"
        case .graphite:
            return "Modern graphite design"
        case .graphiteEcho:
            return "Graphite design with echo effect"
        case .lumenBlack:
            return "Lumen design in black"
        case .lumenBlue:
            return "Lumen design in blue"
        case .studioBlack:
            return "Studio design in black"
        case .studioBlue:
            return "Studio design in blue"
        case .wireframeBlack:
            return "Wireframe design in black"
        case .wireframeBlue:
            return "Wireframe design in blue"
        }
    }
    
    var previewColor: Color {
        switch self {
        case .blueprint, .blueprintEcho:
            return .blue
        case .graphite, .graphiteEcho:
            return .gray
        case .lumenBlack, .studioBlack, .wireframeBlack:
            return .black
        case .lumenBlue, .studioBlue, .wireframeBlue:
            return .blue
        }
    }
}

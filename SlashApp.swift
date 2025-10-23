import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct SlashApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var appIconManager = AppIconManager()

    init() {
        // Configure Firebase early in app lifecycle
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Warning: Could not find GoogleService-Info.plist or CLIENT_ID")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataManager)
                .environmentObject(themeManager)
                .environmentObject(appIconManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Background color for entire app
            themeManager.selectedTheme.primary
                .ignoresSafeArea(.all)
            
            Group {
                if showSplash {
                    SplashView()
                        .onAppear {
                            // Show splash for 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                } else if dataManager.isAuthenticated {
                    MainTabView()
                } else {
                    AuthView()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .onAppear {
            dataManager.configureIfNeeded()
            configureGlobalAppearance()
        }
        .onChange(of: themeManager.selectedTheme) { _ in
            configureGlobalAppearance()
        }
        .task {
            await NotificationsManager.requestAuthorization()
        }
    }
    
    private func configureGlobalAppearance() {
        // Configure UINavigationBar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor(themeManager.selectedTheme.primary)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(themeManager.selectedTheme.accent)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(themeManager.selectedTheme.accent)]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Configure UITabBar appearance with hardcoded colors
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        // Hardcoded colors based on theme
        let backgroundColor: UIColor
        let unselectedColor: UIColor
        let selectedColor: UIColor
        
        if themeManager.selectedTheme.name.contains("Dark") {
            // Dark theme: dark background, white/blue icons
            backgroundColor = UIColor.black
            unselectedColor = UIColor.white
            selectedColor = UIColor(themeManager.selectedTheme.accent)
        } else {
            // Light theme: white background, black/blue icons
            backgroundColor = UIColor.white
            unselectedColor = UIColor.black
            selectedColor = UIColor(themeManager.selectedTheme.accent)
        }
        
        // Force solid background
        tabBarAppearance.backgroundColor = backgroundColor
        
        // Configure normal (unselected) state
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Configure selected state
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Apply appearance to all tab bar states
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Force global tint colors
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
        
        // Force update all existing tab bars with multiple attempts
        DispatchQueue.main.async {
            // First attempt - immediate
            UIApplication.shared.windows.forEach { window in
                window.subviews.forEach { subview in
                    if let tabBar = subview as? UITabBar {
                        tabBar.standardAppearance = tabBarAppearance
                        tabBar.scrollEdgeAppearance = tabBarAppearance
                        tabBar.tintColor = selectedColor
                        tabBar.unselectedItemTintColor = unselectedColor
                        tabBar.backgroundColor = backgroundColor
                        tabBar.isTranslucent = false
                        tabBar.barTintColor = backgroundColor
                    }
                }
            }
            
            // Second attempt - after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIApplication.shared.windows.forEach { window in
                    window.subviews.forEach { subview in
                        if let tabBar = subview as? UITabBar {
                            tabBar.standardAppearance = tabBarAppearance
                            tabBar.scrollEdgeAppearance = tabBarAppearance
                            tabBar.tintColor = selectedColor
                            tabBar.unselectedItemTintColor = unselectedColor
                            tabBar.backgroundColor = backgroundColor
                            tabBar.isTranslucent = false
                            tabBar.barTintColor = backgroundColor
                        }
                    }
                }
            }
            
            // Third attempt - after longer delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIApplication.shared.windows.forEach { window in
                    window.subviews.forEach { subview in
                        if let tabBar = subview as? UITabBar {
                            tabBar.standardAppearance = tabBarAppearance
                            tabBar.scrollEdgeAppearance = tabBarAppearance
                            tabBar.tintColor = selectedColor
                            tabBar.unselectedItemTintColor = unselectedColor
                            tabBar.backgroundColor = backgroundColor
                            tabBar.isTranslucent = false
                            tabBar.barTintColor = backgroundColor
                        }
                    }
                }
            }
        }
        
        // Configure window background without forcing interface style
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes.forEach { scene in
                if let windowScene = scene as? UIWindowScene {
                    windowScene.windows.forEach { window in
                        window.backgroundColor = UIColor(self.themeManager.selectedTheme.primary)
                    }
                }
            }
        }
    }
}
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image("home-tab")
                        .renderingMode(.template)
                    Text("Home")
                }
                .tag(0)
            
            // Analytics Tab
            AnalyticsView()
                .tabItem {
                    Image("analytics-tab")
                        .renderingMode(.template)
                    Text("Analytics")
                }
                .tag(1)
            
            // Shared Tab
            SharedView()
                .tabItem {
                    Image("sharing-tab")
                        .renderingMode(.template)
                    Text("Shared")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image("profile-tab")
                        .renderingMode(.template)
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(themeManager.selectedTheme.name.contains("Dark") ? .white : .black)
        .onAppear {
            // Force tab bar styling immediately
            DispatchQueue.main.async {
                self.forceTabBarStyling()
                self.configureTabBarAppearance()
            }
        }
        .onChange(of: selectedTab) { _ in
            // Post a notification that tabs changed; interested views can scroll to top
            NotificationCenter.default.post(name: .slashTabChanged, object: selectedTab)
            // Force reconfigure when tab changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                configureTabBarAppearance()
            }
        }
        .onChange(of: themeManager.selectedTheme) { _ in
            // Force reconfigure when theme changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                configureTabBarAppearance()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .slashTabChanged)) { _ in
            // Continuously enforce colors when tabs change
            DispatchQueue.main.async {
                self.forceTabBarStyling()
            }
        }
    }
    
    private func forceTabBarStyling() {
        let backgroundColor: UIColor
        let unselectedColor: UIColor
        let selectedColor: UIColor
        
        if themeManager.selectedTheme.name.contains("Dark") {
            backgroundColor = UIColor.black
            unselectedColor = UIColor.white
            selectedColor = UIColor.white // Make selected same as unselected in dark theme
        } else {
            backgroundColor = UIColor.white
            unselectedColor = UIColor.black
            selectedColor = UIColor.black // Make selected same as unselected in light theme
            print("🔍 Light theme colors: unselected=\(unselectedColor), selected=\(selectedColor)")
        }
        
        // Create appearance with hardcoded colors
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        
        // Force normal state colors
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Force selected state colors
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Also configure compact and inline layouts
        appearance.compactInlineLayoutAppearance.normal.iconColor = unselectedColor
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        appearance.inlineLayoutAppearance.normal.iconColor = unselectedColor
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        appearance.inlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Apply to all appearance states
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Force global tint colors
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
        UITabBar.appearance().backgroundColor = backgroundColor
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().barTintColor = backgroundColor
        
        // Additional aggressive color enforcement for light theme
        if !themeManager.selectedTheme.name.contains("Dark") {
            print("🔧 Applying aggressive light theme color enforcement")
            // Force override any system colors
            UITabBar.appearance().tintColor = UIColor.black
            UITabBar.appearance().unselectedItemTintColor = UIColor.black
        }
        
        // Force update all existing tab bars with multiple attempts
        DispatchQueue.main.async {
            // First attempt
            UIApplication.shared.windows.forEach { window in
                window.subviews.forEach { subview in
                    if let tabBar = subview as? UITabBar {
                        tabBar.standardAppearance = appearance
                        tabBar.scrollEdgeAppearance = appearance
                        tabBar.tintColor = selectedColor
                        tabBar.unselectedItemTintColor = unselectedColor
                        tabBar.backgroundColor = backgroundColor
                        tabBar.isTranslucent = false
                        tabBar.barTintColor = backgroundColor
                        
                        // Force update all tab bar items
                        tabBar.items?.forEach { item in
                            item.image = item.image?.withRenderingMode(.alwaysTemplate)
                        }
                        
                        // Additional light theme enforcement
                        if !self.themeManager.selectedTheme.name.contains("Dark") {
                            tabBar.tintColor = UIColor.black
                            tabBar.unselectedItemTintColor = UIColor.black
                            print("🔧 Forced light theme colors on tab bar (first attempt)")
                        }
                    }
                }
            }
            
            // Second attempt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIApplication.shared.windows.forEach { window in
                    window.subviews.forEach { subview in
                        if let tabBar = subview as? UITabBar {
                            tabBar.standardAppearance = appearance
                            tabBar.scrollEdgeAppearance = appearance
                            tabBar.tintColor = selectedColor
                            tabBar.unselectedItemTintColor = unselectedColor
                            tabBar.backgroundColor = backgroundColor
                            tabBar.isTranslucent = false
                            tabBar.barTintColor = backgroundColor
                            
                            // Force update all tab bar items
                            tabBar.items?.forEach { item in
                                item.image = item.image?.withRenderingMode(.alwaysTemplate)
                            }
                            
                            // Additional light theme enforcement
                            if !self.themeManager.selectedTheme.name.contains("Dark") {
                                tabBar.tintColor = UIColor.black
                                tabBar.unselectedItemTintColor = UIColor.black
                                print("🔧 Forced light theme colors on tab bar (second attempt)")
                            }
                        }
                    }
                }
            }
            
            // Third attempt after longer delay to ensure persistence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIApplication.shared.windows.forEach { window in
                    window.subviews.forEach { subview in
                        if let tabBar = subview as? UITabBar {
                            tabBar.tintColor = selectedColor
                            tabBar.unselectedItemTintColor = unselectedColor
                            tabBar.backgroundColor = backgroundColor
                            tabBar.isTranslucent = false
                            tabBar.barTintColor = backgroundColor
                            
                            // Additional light theme enforcement
                            if !self.themeManager.selectedTheme.name.contains("Dark") {
                                tabBar.tintColor = UIColor.black
                                tabBar.unselectedItemTintColor = UIColor.black
                                print("🔧 Forced light theme colors on tab bar (third attempt)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func configureTabBarAppearance() {
        // Reapply tab bar colors when theme changes
        DispatchQueue.main.async {
            let backgroundColor: UIColor
            let unselectedColor: UIColor
            let selectedColor: UIColor
            
            if self.themeManager.selectedTheme.name.contains("Dark") {
                backgroundColor = UIColor.black
                unselectedColor = UIColor.white
                selectedColor = UIColor.white // Make selected same as unselected in dark theme
            } else {
                backgroundColor = UIColor.white
                unselectedColor = UIColor.black
                selectedColor = UIColor.black // Make selected same as unselected in light theme
            }
            
            // Force update all tab bars
            UIApplication.shared.windows.forEach { window in
                window.subviews.forEach { subview in
                    if let tabBar = subview as? UITabBar {
                        tabBar.tintColor = selectedColor
                        tabBar.unselectedItemTintColor = unselectedColor
                        tabBar.backgroundColor = backgroundColor
                        tabBar.isTranslucent = false
                        tabBar.barTintColor = backgroundColor
                        
                        // Force update all tab bar items
                        tabBar.items?.forEach { item in
                            item.image = item.image?.withRenderingMode(.alwaysTemplate)
                        }
                        
                        // Additional light theme enforcement
                        if !self.themeManager.selectedTheme.name.contains("Dark") {
                            tabBar.tintColor = UIColor.black
                            tabBar.unselectedItemTintColor = UIColor.black
                            print("🔧 Forced light theme colors in configureTabBarAppearance")
                        }
                    }
                }
            }
        }
    }
    
    private func forceLightThemeColors() {
        print("🔧 Force light theme colors called")
        
        // Override all possible tab bar color properties
        UITabBar.appearance().tintColor = UIColor.black
        UITabBar.appearance().unselectedItemTintColor = UIColor.black
        UITabBar.appearance().backgroundColor = UIColor.white
        UITabBar.appearance().barTintColor = UIColor.white
        
        // Force update all existing tab bars
        DispatchQueue.main.async {
            UIApplication.shared.windows.forEach { window in
                window.subviews.forEach { subview in
                    if let tabBar = subview as? UITabBar {
                        tabBar.tintColor = UIColor.black
                        tabBar.unselectedItemTintColor = UIColor.black
                        tabBar.backgroundColor = UIColor.white
                        tabBar.barTintColor = UIColor.white
                        tabBar.isTranslucent = false
                        
                        // Force all items to use template rendering
                        tabBar.items?.forEach { item in
                            item.image = item.image?.withRenderingMode(.alwaysTemplate)
                        }
                        
                        print("🔧 Applied aggressive light theme colors to tab bar")
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let slashTabChanged = Notification.Name("slashTabChanged")
}


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
        }
        .preferredColorScheme(preferredColorScheme)
        .task {
            await NotificationsManager.requestAuthorization()
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch themeManager.choice {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

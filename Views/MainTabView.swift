import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image("home-tab")
                        .renderingMode(.template)
                    Text("Home")
                }
                .tag(0)

            AnalyticsView()
                .tabItem {
                    Image("analytics-tab")
                        .renderingMode(.template)
                    Text("Analytics")
                }
                .tag(1)

            SharedView()
                .tabItem {
                    Image("sharing-tab")
                        .renderingMode(.template)
                    Text("Shared")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Image("profile-tab")
                        .renderingMode(.template)
                    Text("Profile")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { _ in
            NotificationCenter.default.post(name: .slashTabChanged, object: selectedTab)
        }
    }
}

extension Notification.Name {
    static let slashTabChanged = Notification.Name("slashTabChanged")
}

#Preview {
    MainTabView()
        .environmentObject(DataManager())
        .environmentObject(ThemeManager())
        .environmentObject(AppIconManager())
}

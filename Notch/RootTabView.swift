import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NotchHomeView()
                .tabItem {
                    Label("Growth", systemImage: "ruler.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(NOTheme.skyDeep)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(NOTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(NotchStore())
        .environmentObject(PurchaseManager())
}

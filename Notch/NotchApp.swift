import SwiftUI

@main
struct NotchApp: App {
    @StateObject private var store = NotchStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.light)
        }
    }
}

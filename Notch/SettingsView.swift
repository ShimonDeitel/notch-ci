import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: NotchStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("notch_units_metric") private var useMetric: Bool = false
    @State private var activeSheet: NotchSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Toggle("Use centimeters instead of inches", isOn: $useMetric)
                        .accessibilityIdentifier("useMetricToggle")
                }

                Section("Children") {
                    ForEach(store.children) { child in
                        Button(child.name) {
                            activeSheet = .editChild(child)
                        }
                        .buttonStyle(.plain)
                    }
                    Button("Add Child") {
                        if store.canAddChild(isPro: purchases.isPro) {
                            activeSheet = .addChild
                        } else {
                            activeSheet = .paywall
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settingsAddChildButton")
                }

                Section("Notch Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(NOTheme.grass)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(NOTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/notch-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(NOTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all children and measurements?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addChild:
                    ChildFormView(existing: nil)
                case .editChild(let child):
                    ChildFormView(existing: child)
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotchStore())
        .environmentObject(PurchaseManager())
}

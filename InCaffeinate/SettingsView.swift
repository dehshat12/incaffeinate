import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var controller: CaffeinateController
    @AppStorage("runOnLogin") private var runOnLogin = false
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("defaultTimerMinutes") private var defaultTimerMinutes = 30
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Divider()
            
            // Settings Options
            VStack(alignment: .leading, spacing: 16) {
                // Run on Login
                Toggle("Run on Login", isOn: $runOnLogin)
                    .onChange(of: runOnLogin) { newValue in
                        setLoginItem(enabled: newValue)
                    }
                
                // Show Notifications
                Toggle("Show Notifications", isOn: $showNotifications)
            }
            
            Spacer()
            
            Divider()
            
            // Status
            HStack {
                VStack(alignment: .leading) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(controller.isActive ? "Active" : "Inactive")
                        .font(.headline)
                        .foregroundColor(controller.isActive ? .green : .secondary)
                }
                
                Spacer()
                
                if controller.isActive && controller.remainingTime > 0 {
                    VStack(alignment: .trailing) {
                        Text("Time Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(controller.formattedRemainingTime)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 480)
    }
    
    private func setLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") login item: \(error)")
            }
        } else {
            // Fallback for older macOS versions
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.yourapp.InCaffeinate"
            SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
        }
    }
}

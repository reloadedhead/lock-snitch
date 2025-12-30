import SwiftUI

@main
struct LockSnitchApp: App {
    @StateObject private var lockMonitor = LockStatusMonitor()
    
    init() {
        // Set default values on first launch
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "webhookEnabled") == nil {
            defaults.set(true, forKey: "webhookEnabled")
        }
        if defaults.object(forKey: "lockStatusParamName") == nil {
            defaults.set("state", forKey: "lockStatusParamName")
        }
        if defaults.object(forKey: "webhookBaseURL") == nil {
            defaults.set("http://homebridge-ip:51828", forKey: "webhookBaseURL")
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(lockMonitor)
        } label: {
            Image(systemName: lockMonitor.isLocked ? "lock.fill" : "lock.open.fill")
        }
        
        Settings {
            SettingsView()
                .environmentObject(lockMonitor)
        }
    }
}

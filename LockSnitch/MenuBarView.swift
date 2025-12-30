import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var lockMonitor: LockStatusMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lock Snitch")
                .font(.headline)
            
            Divider()
            
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    openSettings()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.plain)
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
    }
    
    private func openSettings() {
        if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}

#Preview("Unlocked State") {
    MenuBarView()
        .environmentObject({
            let monitor = LockStatusMonitor()
            monitor.isLocked = false
            return monitor
        }())
        .frame(width: 250)
}

#Preview("Locked State") {
    MenuBarView()
        .environmentObject({
            let monitor = LockStatusMonitor()
            monitor.isLocked = true
            return monitor
        }())
        .frame(width: 250)
}

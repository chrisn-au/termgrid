import SwiftUI

@main
struct TermGridApp: App {
    @StateObject private var config = ConfigManager()

    var body: some Scene {
        // Single WindowGroup handles both launcher (nil) and grid (instance ID)
        WindowGroup(for: String.self) { $instanceId in
            if let id = instanceId, let instance = config.instance(for: id) {
                TerminalGridView(instance: instance)
                    .environmentObject(config)
                    .navigationTitle("\(instance.name) — \(instance.directory)")
                    .frame(minWidth: 800, minHeight: 500)
            } else {
                LauncherView()
                    .environmentObject(config)
                    .navigationTitle("TermGrid")
                    .frame(minWidth: 500, minHeight: 400)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(config)
        }
    }
}

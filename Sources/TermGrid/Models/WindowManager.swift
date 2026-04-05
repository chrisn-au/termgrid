import AppKit

/// Tracks which NSWindow belongs to which instance ID
class WindowManager {
    static let shared = WindowManager()

    private var windows: [String: NSWindow] = [:]

    func register(instanceId: String, window: NSWindow) {
        windows[instanceId] = window
    }

    func window(for instanceId: String) -> NSWindow? {
        // Clean up deallocated windows
        if let w = windows[instanceId], w.isVisible {
            return w
        }
        windows.removeValue(forKey: instanceId)
        return nil
    }
}

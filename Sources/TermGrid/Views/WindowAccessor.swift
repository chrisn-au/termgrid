import SwiftUI
import AppKit

/// Invisible view that finds its hosting NSWindow and registers it with WindowManager
struct WindowAccessor: NSViewRepresentable {
    let instanceId: String

    func makeNSView(context: Context) -> NSView {
        let view = WindowFinderView(instanceId: instanceId)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private class WindowFinderView: NSView {
    let instanceId: String

    init(instanceId: String) {
        self.instanceId = instanceId
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            WindowManager.shared.register(instanceId: instanceId, window: window)
        }
    }
}

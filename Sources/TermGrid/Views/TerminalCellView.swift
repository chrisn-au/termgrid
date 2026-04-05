import SwiftUI
import SwiftTerm
import AppKit

struct TerminalCellView: NSViewRepresentable {
    let directory: String
    let backgroundColor: NSColor
    let fontSize: CGFloat

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let shellName = "-" + (shell as NSString).lastPathComponent

        // Build environment with ZDOTDIR and TERMGRID_DIR
        let zshConfigDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/termgrid/zsh").path
        var env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
        env.append("ZDOTDIR=\(zshConfigDir)")
        env.append("TERMGRID_DIR=\(directory)")

        terminalView.startProcess(
            executable: shell,
            args: [],
            environment: env,
            execName: shellName,
            currentDirectory: directory
        )

        terminalView.nativeBackgroundColor = backgroundColor
        terminalView.nativeForegroundColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        return terminalView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        nsView.nativeBackgroundColor = backgroundColor
        nsView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}

// Hex <-> NSColor helpers
extension NSColor {
    convenience init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }

        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)

        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "#1a1a1f" }
        let r = Int(c.redComponent * 255)
        let g = Int(c.greenComponent * 255)
        let b = Int(c.blueComponent * 255)
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}

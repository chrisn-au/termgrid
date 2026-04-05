import SwiftUI
import SwiftTerm
import AppKit

struct TerminalCellView: NSViewRepresentable {
    let directory: String
    let backgroundColor: NSColor
    let fontSize: CGFloat
    let tmuxSessionName: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        context.coordinator.terminalView = terminalView
        terminalView.processDelegate = context.coordinator

        context.coordinator.startProcess(in: terminalView)

        terminalView.nativeBackgroundColor = backgroundColor
        terminalView.nativeForegroundColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        return terminalView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        nsView.nativeBackgroundColor = backgroundColor
        nsView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var parent: TerminalCellView
        weak var terminalView: LocalProcessTerminalView?

        init(_ parent: TerminalCellView) {
            self.parent = parent
        }

        func startProcess(in tv: LocalProcessTerminalView) {
            if let sessionName = parent.tmuxSessionName, let tmuxPath = TerminalCellView.findTmux() {
                let env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
                tv.startProcess(
                    executable: tmuxPath,
                    args: ["new-session", "-A", "-s", sessionName, "-c", parent.directory],
                    environment: env,
                    execName: "tmux",
                    currentDirectory: parent.directory
                )
            } else {
                let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
                let shellName = "-" + (shell as NSString).lastPathComponent

                let zshConfigDir = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".config/termgrid/zsh").path
                var env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
                env.append("ZDOTDIR=\(zshConfigDir)")
                env.append("TERMGRID_DIR=\(parent.directory)")

                tv.startProcess(
                    executable: shell,
                    args: [],
                    environment: env,
                    execName: shellName,
                    currentDirectory: parent.directory
                )
            }
        }

        // MARK: - LocalProcessTerminalViewDelegate

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            // Restart shell after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, let tv = self.terminalView else { return }
                self.startProcess(in: tv)
            }
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    }

    static func findTmux() -> String? {
        let candidates = [
            "/opt/homebrew/bin/tmux",
            "/usr/local/bin/tmux",
            "/usr/bin/tmux",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
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

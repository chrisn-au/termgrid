import Foundation

class ConfigManager: ObservableObject {
    @Published var appConfig: AppConfig = .default

    private let configURL: URL

    init() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("termgrid", isDirectory: true)

        self.configURL = configDir.appendingPathComponent("config.json")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        // Load config or create default
        if FileManager.default.fileExists(atPath: configURL.path) {
            loadConfig()
        } else {
            appConfig = .default
            save()
        }

        // Set up custom zsh config for prompt
        setupZshConfig(configDir: configDir)
    }

    /// ZDOTDIR path for custom prompt
    var zshConfigDir: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/termgrid/zsh", isDirectory: true).path
    }

    private func setupZshConfig(configDir: URL) {
        let zshDir = configDir.appendingPathComponent("zsh", isDirectory: true)
        try? FileManager.default.createDirectory(at: zshDir, withIntermediateDirectories: true)

        let zshenv = """
        # Forward to user's .zshenv
        [[ -f "$HOME/.zshenv" ]] && source "$HOME/.zshenv"
        """

        let zprofile = """
        # Forward to user's .zprofile
        [[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
        """

        let zshrc = """
        # Forward to user's .zshrc
        [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"

        # TermGrid custom prompt
        if [[ -n "$TERMGRID_DIR" ]]; then
          autoload -Uz add-zsh-hook
          _termgrid_set_prompt() {
            if [[ "$PWD" == "$TERMGRID_DIR"* ]]; then
              local base="${TERMGRID_DIR##*/}"
              local rel="${PWD#$TERMGRID_DIR}"
              PROMPT="%F{cyan}${base}${rel}%f %# "
            else
              PROMPT="%F{cyan}%~%f %# "
            fi
          }
          add-zsh-hook precmd _termgrid_set_prompt
        fi
        """

        let zlogin = """
        # Forward to user's .zlogin
        [[ -f "$HOME/.zlogin" ]] && source "$HOME/.zlogin"
        """

        let files: [(String, String)] = [
            (".zshenv", zshenv),
            (".zprofile", zprofile),
            (".zshrc", zshrc),
            (".zlogin", zlogin),
        ]

        for (name, content) in files {
            let url = zshDir.appendingPathComponent(name)
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func loadConfig() {
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            appConfig = try decoder.decode(AppConfig.self, from: data)
        } catch {
            print("Failed to load config: \(error)")
            appConfig = .default
            save()
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(appConfig)
            try data.write(to: configURL)
        } catch {
            print("Failed to save config: \(error)")
        }
    }

    func instance(for id: String) -> InstanceConfig? {
        appConfig.instances.first { $0.id == id }
    }

    func addInstance() -> InstanceConfig {
        let newInstance = InstanceConfig(
            id: UUID().uuidString,
            name: "Instance \(appConfig.instances.count + 1)",
            directory: FileManager.default.homeDirectoryForCurrentUser.path,
            rows: 1,
            cols: 3,
            columnWidths: nil,
            tileColors: nil,
            layoutMode: nil,
            tabLabels: nil,
            fontSize: nil,
            tileFontSizes: nil,
            tabs: nil,
            isTemplate: nil,
            useTmux: nil
        )
        appConfig.instances.append(newInstance)
        save()
        return newInstance
    }

    func updateInstance(_ instance: InstanceConfig) {
        if let index = appConfig.instances.firstIndex(where: { $0.id == instance.id }) {
            appConfig.instances[index] = instance
            save()
        }
    }

    func deleteInstance(id: String) {
        appConfig.instances.removeAll { $0.id == id }
        save()
    }
}

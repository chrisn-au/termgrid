import Foundation

enum LayoutMode: String, Codable, Hashable {
    case split
    case tabs
}

/// Per-tab configuration — each tab can have its own number of terminal splits
struct TabConfig: Codable, Hashable {
    var label: String
    var splits: Int              // number of side-by-side terminals in this tab
    var colors: [String]?        // per-split background colors
    var fontSizes: [CGFloat]?    // per-split font sizes
    var columnWidths: [CGFloat]? // per-split proportional widths

    func colorForSplit(_ index: Int) -> String {
        if let c = colors, index < c.count, !c[index].isEmpty {
            return c[index]
        }
        return "#1a1a1f"
    }

    func fontSizeForSplit(_ index: Int, fallback: CGFloat) -> CGFloat {
        if let s = fontSizes, index < s.count, s[index] > 0 {
            return s[index]
        }
        return fallback
    }

    var resolvedColumnWidths: [CGFloat] {
        if let w = columnWidths, w.count == splits {
            return w
        }
        return Array(repeating: 1.0 / CGFloat(splits), count: splits)
    }

    mutating func setColorForSplit(_ index: Int, hex: String) {
        if colors == nil { colors = Array(repeating: "", count: splits) }
        while colors!.count < splits { colors!.append("") }
        colors![index] = hex
    }

    mutating func setFontSizeForSplit(_ index: Int, size: CGFloat) {
        if fontSizes == nil { fontSizes = Array(repeating: 0, count: splits) }
        while fontSizes!.count < splits { fontSizes!.append(0) }
        fontSizes![index] = size
    }

    mutating func setColumnWidths(_ widths: [CGFloat]) {
        columnWidths = widths
    }

    static func `default`(label: String = "Terminal", splits: Int = 1) -> TabConfig {
        TabConfig(label: label, splits: splits)
    }
}

struct InstanceConfig: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var directory: String
    var rows: Int
    var cols: Int
    var columnWidths: [CGFloat]?     // used in split mode
    var tileColors: [String]?        // used in split mode
    var layoutMode: LayoutMode?
    var tabLabels: [String]?         // legacy, migrated to tabs
    var fontSize: CGFloat?           // instance-wide fallback (default 11)
    var tileFontSizes: [CGFloat]?    // legacy, migrated to tabs
    var tabs: [TabConfig]?           // per-tab config for tabs mode
    var isTemplate: Bool?             // true = can't be opened, only cloned
    var useTmux: Bool?

    var resolvedLayoutMode: LayoutMode {
        layoutMode ?? .split
    }

    var resolvedFontSize: CGFloat {
        fontSize ?? 11
    }

    var resolvedUseTmux: Bool {
        useTmux ?? false
    }

    /// Resolve tabs array — migrate from legacy flat model if needed
    var resolvedTabs: [TabConfig] {
        if let t = tabs { return t }
        // Migrate from legacy flat model
        let count = rows * cols
        return (0..<count).map { i in
            let label = tabLabels.flatMap { $0.count > i && !$0[i].isEmpty ? $0[i] : nil } ?? "Terminal \(i + 1)"
            let color = tileColors.flatMap { $0.count > i && !$0[i].isEmpty ? $0[i] : nil }
            let fs = tileFontSizes.flatMap { $0.count > i && $0[i] > 0 ? $0[i] : nil }
            return TabConfig(
                label: label,
                splits: 1,
                colors: color.map { [$0] },
                fontSizes: fs.map { [$0] }
            )
        }
    }

    // MARK: - Split mode helpers (unchanged)

    var totalTiles: Int { rows * cols }

    var resolvedColumnWidths: [CGFloat] {
        if let widths = columnWidths, widths.count == cols {
            return widths
        }
        return Array(repeating: 1.0 / CGFloat(cols), count: cols)
    }

    func colorForTile(row: Int, col: Int) -> String {
        let index = row * cols + col
        if let colors = tileColors, index < colors.count, !colors[index].isEmpty {
            return colors[index]
        }
        return "#1a1a1f"
    }

    mutating func setColorForTile(row: Int, col: Int, hex: String) {
        let total = totalTiles
        if tileColors == nil { tileColors = Array(repeating: "", count: total) }
        while tileColors!.count < total { tileColors!.append("") }
        tileColors![row * cols + col] = hex
    }

    func fontSizeForTile(row: Int, col: Int) -> CGFloat {
        let index = row * cols + col
        if let sizes = tileFontSizes, index < sizes.count, sizes[index] > 0 {
            return sizes[index]
        }
        return resolvedFontSize
    }

    mutating func setFontSizeForTile(row: Int, col: Int, size: CGFloat) {
        let total = totalTiles
        if tileFontSizes == nil { tileFontSizes = Array(repeating: 0, count: total) }
        while tileFontSizes!.count < total { tileFontSizes!.append(0) }
        tileFontSizes![row * cols + col] = size
    }

    // MARK: - Tab mutation helpers

    mutating func updateTab(at index: Int, _ transform: (inout TabConfig) -> Void) {
        if tabs == nil { tabs = resolvedTabs }
        guard index < tabs!.count else { return }
        transform(&tabs![index])
    }

    mutating func addTab(label: String = "New Tab", splits: Int = 1) {
        if tabs == nil { tabs = resolvedTabs }
        tabs!.append(TabConfig.default(label: label, splits: splits))
    }

    func cloned(name: String) -> InstanceConfig {
        var copy = self
        copy.id = UUID().uuidString
        copy.name = name
        copy.isTemplate = nil
        copy.useTmux = useTmux
        return copy
    }

    mutating func removeTab(at index: Int) {
        if tabs == nil { tabs = resolvedTabs }
        guard tabs!.count > 1, index < tabs!.count else { return }
        tabs!.remove(at: index)
    }

    static var `default`: InstanceConfig {
        InstanceConfig(
            id: UUID().uuidString,
            name: "Default",
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
    }
}

struct AppConfig: Codable {
    var instances: [InstanceConfig]

    static var `default`: AppConfig {
        AppConfig(instances: [.default])
    }
}

import SwiftUI
import AppKit

struct TerminalGridView: View {
    let instance: InstanceConfig
    @EnvironmentObject var config: ConfigManager
    @State private var columnWidths: [CGFloat] = []
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var selectedTab: Int = 0
    @State private var renamingTabIndex: Int?
    @State private var tabRenameText = ""
    @State private var tabColumnWidths: [Int: [CGFloat]] = [:]  // per-tab column widths for dragging

    static let presetColors: [(name: String, hex: String)] = [
        ("Default Dark",   "#1a1a1f"),
        ("Midnight Blue",  "#0d1b2a"),
        ("Deep Purple",    "#1a0a2e"),
        ("Forest Green",   "#0a1f0a"),
        ("Dark Red",       "#1f0a0a"),
        ("Navy",           "#0a0a2a"),
        ("Charcoal",       "#2b2b2b"),
        ("Slate",          "#1e293b"),
        ("Monokai",        "#272822"),
        ("Solarized Dark", "#002b36"),
        ("Dracula",        "#282a36"),
        ("Nord",           "#2e3440"),
    ]

    var body: some View {
        Group {
            switch instance.resolvedLayoutMode {
            case .split:
                splitView
            case .tabs:
                tabsView
            }
        }
        .background(WindowAccessor(instanceId: instance.id))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    toggleLayoutMode()
                } label: {
                    Label(
                        instance.resolvedLayoutMode == .split ? "Switch to Tabs" : "Switch to Split",
                        systemImage: instance.resolvedLayoutMode == .split ? "rectangle.stack" : "rectangle.split.3x1"
                    )
                }
                .help(instance.resolvedLayoutMode == .split ? "Switch to tab layout" : "Switch to split layout")
            }
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 2) {
                    Button { changeFontSize(-1) } label: {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .help("Decrease font size")
                    Text("\(Int(currentFontSize))pt")
                        .font(.caption)
                        .frame(width: 30)
                    Button { changeFontSize(1) } label: {
                        Image(systemName: "textformat.size.larger")
                    }
                    .help("Increase font size")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: chooseDirectory) {
                    Label("Set Directory", systemImage: "folder")
                }
                .help("Change working directory")
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    renameText = instance.name
                    isRenaming = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                .help("Rename instance")
            }
        }
        .sheet(isPresented: $isRenaming) {
            VStack(spacing: 16) {
                Text("Rename Instance")
                    .font(.headline)
                TextField("Name", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .onSubmit { applyRename() }
                HStack {
                    Button("Cancel") { isRenaming = false }
                        .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("Save") { applyRename() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
    }

    // MARK: - Split Layout (unchanged)

    private var splitView: some View {
        GeometryReader { geo in
            VStack(spacing: 1) {
                ForEach(0..<instance.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<instance.cols, id: \.self) { col in
                            if col > 0 {
                                DragDivider(
                                    colIndex: col,
                                    columnWidths: $columnWidths,
                                    totalWidth: geo.size.width,
                                    onEnd: saveWidths
                                )
                            }
                            let hex = instance.colorForTile(row: row, col: col)
                            let tileFontSize = instance.fontSizeForTile(row: row, col: col)
                            TerminalCellView(
                                directory: instance.directory,
                                backgroundColor: NSColor(hex: hex),
                                fontSize: tileFontSize
                            )
                            .frame(width: widthFor(col: col, totalWidth: geo.size.width))
                            .contextMenu {
                                splitTileContextMenu(row: row, col: col, hex: hex, fontSize: tileFontSize)
                            }
                        }
                    }
                }
            }
            .background(Color.black)
            .onAppear {
                columnWidths = instance.resolvedColumnWidths
            }
        }
    }

    // MARK: - Tabs Layout (with per-tab splits)

    private var tabsView: some View {
        let tabs = instance.resolvedTabs

        return VStack(spacing: 0) {
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { tabIndex, tab in
                        let isSelected = selectedTab == tabIndex

                        if renamingTabIndex == tabIndex {
                            TextField("Name", text: $tabRenameText, onCommit: {
                                applyTabRename(index: tabIndex)
                            })
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                        } else {
                            Button {
                                selectedTab = tabIndex
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(nsColor: NSColor(hex: tab.colorForSplit(0))))
                                        .frame(width: 8, height: 8)
                                    Text(tab.label)
                                        .font(.system(size: 12))
                                    if tab.splits > 1 {
                                        Text("(\(tab.splits))")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                tabContextMenu(tabIndex: tabIndex, tab: tab)
                            }
                        }
                    }

                    // Add tab button
                    Button {
                        var updated = instance
                        updated.addTab()
                        config.updateInstance(updated)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                    .help("Add tab")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Terminal content — all tabs exist, only selected is visible
            GeometryReader { geo in
                ZStack {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { tabIndex, tab in
                        tabContent(tabIndex: tabIndex, tab: tab, totalWidth: geo.size.width)
                            .opacity(selectedTab == tabIndex ? 1 : 0)
                            .allowsHitTesting(selectedTab == tabIndex)
                    }
                }
            }
        }
        .onAppear {
            // Initialize per-tab column widths
            for (i, tab) in tabs.enumerated() {
                tabColumnWidths[i] = tab.resolvedColumnWidths
            }
        }
    }

    /// Render a single tab's content — could be 1 terminal or multiple splits
    private func tabContent(tabIndex: Int, tab: TabConfig, totalWidth: CGFloat) -> some View {
        let widths = tabColumnWidths[tabIndex] ?? tab.resolvedColumnWidths

        return HStack(spacing: 0) {
            ForEach(0..<tab.splits, id: \.self) { splitIndex in
                if splitIndex > 0 {
                    TabDragDivider(
                        tabIndex: tabIndex,
                        colIndex: splitIndex,
                        tabColumnWidths: $tabColumnWidths,
                        totalWidth: totalWidth,
                        onEnd: { saveTabWidths(tabIndex: tabIndex) }
                    )
                }
                let hex = tab.colorForSplit(splitIndex)
                let fs = tab.fontSizeForSplit(splitIndex, fallback: instance.resolvedFontSize)
                TerminalCellView(
                    directory: instance.directory,
                    backgroundColor: NSColor(hex: hex),
                    fontSize: fs
                )
                .frame(width: tabSplitWidth(widths: widths, splitIndex: splitIndex, totalWidth: totalWidth, totalSplits: tab.splits))
                .contextMenu {
                    splitInTabContextMenu(tabIndex: tabIndex, splitIndex: splitIndex, tab: tab)
                }
            }
        }
    }

    private func tabSplitWidth(widths: [CGFloat], splitIndex: Int, totalWidth: CGFloat, totalSplits: Int) -> CGFloat {
        guard splitIndex < widths.count else {
            return totalWidth / CGFloat(totalSplits)
        }
        let dividerSpace = CGFloat(max(0, totalSplits - 1)) * 4.0
        return widths[splitIndex] * (totalWidth - dividerSpace)
    }

    // MARK: - Context Menus

    @ViewBuilder
    private func tabContextMenu(tabIndex: Int, tab: TabConfig) -> some View {
        Button("Rename Tab...") {
            tabRenameText = tab.label
            renamingTabIndex = tabIndex
        }
        Divider()
        Menu("Splits: \(tab.splits)") {
            ForEach(1...5, id: \.self) { n in
                Button {
                    var updated = instance
                    updated.updateTab(at: tabIndex) { $0.splits = n }
                    config.updateInstance(updated)
                    // Reset column widths for this tab
                    tabColumnWidths[tabIndex] = Array(repeating: 1.0 / CGFloat(n), count: n)
                } label: {
                    HStack {
                        Text("\(n)")
                        if tab.splits == n {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        Divider()
        if instance.resolvedTabs.count > 1 {
            Button("Delete Tab", role: .destructive) {
                var updated = instance
                updated.removeTab(at: tabIndex)
                config.updateInstance(updated)
                if selectedTab >= instance.resolvedTabs.count - 1 {
                    selectedTab = max(0, selectedTab - 1)
                }
            }
        }
    }

    @ViewBuilder
    private func splitInTabContextMenu(tabIndex: Int, splitIndex: Int, tab: TabConfig) -> some View {
        let hex = tab.colorForSplit(splitIndex)
        let fs = tab.fontSizeForSplit(splitIndex, fallback: instance.resolvedFontSize)

        Menu("Font Size (\(Int(fs))pt)") {
            ForEach([8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 24], id: \.self) { size in
                Button {
                    var updated = instance
                    updated.updateTab(at: tabIndex) { $0.setFontSizeForSplit(splitIndex, size: CGFloat(size)) }
                    config.updateInstance(updated)
                } label: {
                    HStack {
                        Text("\(size)pt")
                        if Int(fs) == size { Spacer(); Image(systemName: "checkmark") }
                    }
                }
            }
        }
        Divider()
        Text("Background Color").font(.headline)
        Divider()
        ForEach(Self.presetColors, id: \.hex) { preset in
            Button {
                var updated = instance
                updated.updateTab(at: tabIndex) { $0.setColorForSplit(splitIndex, hex: preset.hex) }
                config.updateInstance(updated)
            } label: {
                HStack {
                    Circle().fill(Color(nsColor: NSColor(hex: preset.hex))).frame(width: 12, height: 12)
                    Text(preset.name)
                    if preset.hex == hex { Spacer(); Image(systemName: "checkmark") }
                }
            }
        }
        Divider()
        Button("Custom Color...") {
            pickTabSplitColor(tabIndex: tabIndex, splitIndex: splitIndex, currentHex: hex)
        }
    }

    @ViewBuilder
    private func splitTileContextMenu(row: Int, col: Int, hex: String, fontSize: CGFloat) -> some View {
        Menu("Font Size (\(Int(fontSize))pt)") {
            ForEach([8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 24], id: \.self) { size in
                Button {
                    setTileFontSize(row: row, col: col, size: CGFloat(size))
                } label: {
                    HStack {
                        Text("\(size)pt")
                        if Int(fontSize) == size { Spacer(); Image(systemName: "checkmark") }
                    }
                }
            }
        }
        Divider()
        Text("Background Color").font(.headline)
        Divider()
        ForEach(Self.presetColors, id: \.hex) { preset in
            Button {
                setTileColor(row: row, col: col, hex: preset.hex)
            } label: {
                HStack {
                    Circle().fill(Color(nsColor: NSColor(hex: preset.hex))).frame(width: 12, height: 12)
                    Text(preset.name)
                    if preset.hex == hex { Spacer(); Image(systemName: "checkmark") }
                }
            }
        }
        Divider()
        Button("Custom Color...") {
            pickCustomColor(row: row, col: col, currentHex: hex)
        }
    }

    // MARK: - Computed

    private var currentFontSize: CGFloat {
        if instance.resolvedLayoutMode == .tabs {
            let tabs = instance.resolvedTabs
            guard selectedTab < tabs.count else { return instance.resolvedFontSize }
            return tabs[selectedTab].fontSizeForSplit(0, fallback: instance.resolvedFontSize)
        }
        return instance.resolvedFontSize
    }

    // MARK: - Actions

    private func changeFontSize(_ delta: CGFloat) {
        if instance.resolvedLayoutMode == .tabs {
            let tabs = instance.resolvedTabs
            guard selectedTab < tabs.count else { return }
            let tab = tabs[selectedTab]
            // Change all splits in current tab
            var updated = instance
            for s in 0..<tab.splits {
                let current = tab.fontSizeForSplit(s, fallback: instance.resolvedFontSize)
                updated.updateTab(at: selectedTab) { $0.setFontSizeForSplit(s, size: max(8, min(32, current + delta))) }
            }
            config.updateInstance(updated)
        } else {
            var updated = instance
            updated.fontSize = max(8, min(32, instance.resolvedFontSize + delta))
            config.updateInstance(updated)
        }
    }

    private func toggleLayoutMode() {
        var updated = instance
        if instance.resolvedLayoutMode == .split {
            updated.layoutMode = .tabs
            // Migrate to tabs model if needed
            if updated.tabs == nil {
                updated.tabs = updated.resolvedTabs
            }
        } else {
            updated.layoutMode = .split
        }
        config.updateInstance(updated)
    }

    private func widthFor(col: Int, totalWidth: CGFloat) -> CGFloat {
        guard col < columnWidths.count else {
            return totalWidth / CGFloat(instance.cols)
        }
        let dividerSpace = CGFloat(max(0, instance.cols - 1)) * 4.0
        return columnWidths[col] * (totalWidth - dividerSpace)
    }

    private func saveWidths() {
        var updated = instance
        updated.columnWidths = columnWidths
        config.updateInstance(updated)
    }

    private func saveTabWidths(tabIndex: Int) {
        guard let widths = tabColumnWidths[tabIndex] else { return }
        var updated = instance
        updated.updateTab(at: tabIndex) { $0.setColumnWidths(widths) }
        config.updateInstance(updated)
    }

    private func setTileFontSize(row: Int, col: Int, size: CGFloat) {
        var updated = instance
        updated.setFontSizeForTile(row: row, col: col, size: size)
        config.updateInstance(updated)
    }

    private func setTileColor(row: Int, col: Int, hex: String) {
        var updated = instance
        updated.setColorForTile(row: row, col: col, hex: hex)
        config.updateInstance(updated)
    }

    private func pickCustomColor(row: Int, col: Int, currentHex: String) {
        let panel = NSColorPanel.shared
        panel.color = NSColor(hex: currentHex)
        panel.setTarget(nil)
        panel.setAction(nil)
        panel.orderFront(nil)
        let observer = ColorObserver(row: row, col: col) { r, c, color in
            setTileColor(row: r, col: c, hex: color.hexString)
        }
        panel.setTarget(observer)
        panel.setAction(#selector(ColorObserver.colorChanged(_:)))
        ColorObserver.current = observer
    }

    private func pickTabSplitColor(tabIndex: Int, splitIndex: Int, currentHex: String) {
        let panel = NSColorPanel.shared
        panel.color = NSColor(hex: currentHex)
        panel.setTarget(nil)
        panel.setAction(nil)
        panel.orderFront(nil)
        let observer = ColorObserver(row: tabIndex, col: splitIndex) { t, s, color in
            var updated = instance
            updated.updateTab(at: t) { $0.setColorForSplit(s, hex: color.hexString) }
            config.updateInstance(updated)
        }
        panel.setTarget(observer)
        panel.setAction(#selector(ColorObserver.colorChanged(_:)))
        ColorObserver.current = observer
    }

    private func applyRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            var updated = instance
            updated.name = trimmed
            config.updateInstance(updated)
        }
        isRenaming = false
    }

    private func applyTabRename(index: Int) {
        let trimmed = tabRenameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            var updated = instance
            updated.updateTab(at: index) { $0.label = trimmed }
            config.updateInstance(updated)
        }
        renamingTabIndex = nil
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: instance.directory)
        panel.prompt = "Set Directory"
        if panel.runModal() == .OK, let url = panel.url {
            var updated = instance
            updated.directory = url.path
            config.updateInstance(updated)
        }
    }
}

// MARK: - Helpers

class ColorObserver: NSObject {
    static var current: ColorObserver?
    let row: Int
    let col: Int
    let onChange: (Int, Int, NSColor) -> Void

    init(row: Int, col: Int, onChange: @escaping (Int, Int, NSColor) -> Void) {
        self.row = row
        self.col = col
        self.onChange = onChange
    }

    @objc func colorChanged(_ sender: NSColorPanel) {
        onChange(row, col, sender.color)
    }
}

struct DragDivider: View {
    let colIndex: Int
    @Binding var columnWidths: [CGFloat]
    let totalWidth: CGFloat
    let onEnd: () -> Void
    @State private var isDragging = false

    var body: some View {
        Rectangle()
            .fill(isDragging ? Color.accentColor : Color.gray.opacity(0.4))
            .frame(width: 4)
            .contentShape(Rectangle().inset(by: -4))
            .onHover { h in if h { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() } }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        guard colIndex > 0, colIndex < columnWidths.count else { return }
                        let dividerSpace = CGFloat(max(0, columnWidths.count - 1)) * 4.0
                        let delta = value.translation.width / (totalWidth - dividerSpace)
                        let newLeft = columnWidths[colIndex - 1] + delta
                        let newRight = columnWidths[colIndex] - delta
                        if newLeft >= 0.05 && newRight >= 0.05 {
                            columnWidths[colIndex - 1] = newLeft
                            columnWidths[colIndex] = newRight
                        }
                    }
                    .onEnded { _ in isDragging = false; onEnd() }
            )
    }
}

/// Drag divider for tab splits — uses per-tab column widths dict
struct TabDragDivider: View {
    let tabIndex: Int
    let colIndex: Int
    @Binding var tabColumnWidths: [Int: [CGFloat]]
    let totalWidth: CGFloat
    let onEnd: () -> Void
    @State private var isDragging = false

    var body: some View {
        Rectangle()
            .fill(isDragging ? Color.accentColor : Color.gray.opacity(0.4))
            .frame(width: 4)
            .contentShape(Rectangle().inset(by: -4))
            .onHover { h in if h { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() } }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        guard var widths = tabColumnWidths[tabIndex],
                              colIndex > 0, colIndex < widths.count else { return }
                        let dividerSpace = CGFloat(max(0, widths.count - 1)) * 4.0
                        let delta = value.translation.width / (totalWidth - dividerSpace)
                        let newLeft = widths[colIndex - 1] + delta
                        let newRight = widths[colIndex] - delta
                        if newLeft >= 0.05 && newRight >= 0.05 {
                            widths[colIndex - 1] = newLeft
                            widths[colIndex] = newRight
                            tabColumnWidths[tabIndex] = widths
                        }
                    }
                    .onEnded { _ in isDragging = false; onEnd() }
            )
    }
}

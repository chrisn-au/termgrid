import SwiftUI
import AppKit

struct LauncherView: View {
    @EnvironmentObject var config: ConfigManager
    @Environment(\.openWindow) private var openWindow
    @State private var renamingId: String?
    @State private var renameText = ""
    @State private var cloneNameText = ""
    @State private var cloningFromId: String?

    private var instances: [InstanceConfig] {
        config.appConfig.instances.filter { $0.isTemplate != true }
    }

    private var templates: [InstanceConfig] {
        config.appConfig.instances.filter { $0.isTemplate == true }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TermGrid")
                .font(.title2.bold())

            List {
                // Instances
                Section("Instances") {
                    ForEach(instances) { instance in
                        instanceRow(instance)
                    }
                }

                // Templates
                if !templates.isEmpty {
                    Section("Templates") {
                        ForEach(templates) { template in
                            templateRow(template)
                        }
                    }
                }
            }

            HStack {
                Button("Add Instance") {
                    _ = config.addInstance()
                }
                Spacer()
                Button("Open All") {
                    for instance in instances {
                        jumpToOrOpen(instance)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: Binding(
            get: { cloningFromId != nil },
            set: { if !$0 { cloningFromId = nil } }
        )) {
            if let sourceId = cloningFromId,
               let source = config.instance(for: sourceId) {
                VStack(spacing: 16) {
                    Text("Clone from \"\(source.name)\"")
                        .font(.headline)
                    TextField("New instance name", text: $cloneNameText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                        .onSubmit { performClone(from: source) }
                    HStack {
                        Button("Cancel") { cloningFromId = nil }
                            .keyboardShortcut(.cancelAction)
                        Spacer()
                        Button("Clone") { performClone(from: source) }
                            .keyboardShortcut(.defaultAction)
                            .disabled(cloneNameText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Instance Row

    private func instanceRow(_ instance: InstanceConfig) -> some View {
        HStack {
            VStack(alignment: .leading) {
                if renamingId == instance.id {
                    TextField("Name", text: $renameText, onCommit: {
                        applyRename(id: instance.id)
                    })
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                } else {
                    Text(instance.name)
                        .font(.headline)
                        .onTapGesture { jumpToOrOpen(instance) }
                        .help("Click to jump to this instance")
                }
                Text(instanceSubtitle(instance))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Open") {
                jumpToOrOpen(instance)
            }
        }
        .contextMenu {
            Button("Rename...") {
                renameText = instance.name
                renamingId = instance.id
            }
            Button("Set Directory...") {
                chooseDirectory(for: instance)
            }
            Divider()
            Button("Clone...") {
                cloneNameText = "\(instance.name) Copy"
                cloningFromId = instance.id
            }
            Button("Save as Template") {
                var template = instance
                template.id = UUID().uuidString
                template.name = "\(instance.name) (Template)"
                template.isTemplate = true
                config.appConfig.instances.append(template)
                config.save()
            }
            Divider()
            Button("Delete", role: .destructive) {
                config.deleteInstance(id: instance.id)
            }
        }
    }

    // MARK: - Template Row

    private func templateRow(_ template: InstanceConfig) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if renamingId == template.id {
                        TextField("Name", text: $renameText, onCommit: {
                            applyRename(id: template.id)
                        })
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                    } else {
                        Text(template.name)
                            .font(.headline)
                    }
                }
                Text(instanceSubtitle(template))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Clone") {
                cloneNameText = template.name.replacingOccurrences(of: " (Template)", with: "")
                cloningFromId = template.id
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .contextMenu {
            Button("Clone...") {
                cloneNameText = template.name.replacingOccurrences(of: " (Template)", with: "")
                cloningFromId = template.id
            }
            Button("Rename...") {
                renameText = template.name
                renamingId = template.id
            }
            Divider()
            Button("Delete", role: .destructive) {
                config.deleteInstance(id: template.id)
            }
        }
    }

    // MARK: - Helpers

    private func instanceSubtitle(_ instance: InstanceConfig) -> String {
        let layout = instance.resolvedLayoutMode == .tabs ? "tabs" : "split"
        let count = instance.resolvedLayoutMode == .tabs ? "\(instance.resolvedTabs.count) tabs" : "\(instance.cols)×\(instance.rows)"
        return "\(count) (\(layout)) — \(instance.directory)"
    }

    private func jumpToOrOpen(_ instance: InstanceConfig) {
        guard instance.isTemplate != true else { return }
        if let window = WindowManager.shared.window(for: instance.id) {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        } else {
            openWindow(value: instance.id)
        }
    }

    private func performClone(from source: InstanceConfig) {
        let trimmed = cloneNameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: source.directory)
        panel.prompt = "Set Directory"
        panel.message = "Choose working directory for \"\(trimmed)\""

        guard panel.runModal() == .OK, let url = panel.url else { return }

        var cloned = source.cloned(name: trimmed)
        cloned.directory = url.path
        config.appConfig.instances.append(cloned)
        config.save()
        cloningFromId = nil
    }

    private func applyRename(id: String) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, var instance = config.instance(for: id) {
            instance.name = trimmed
            config.updateInstance(instance)
        }
        renamingId = nil
    }

    private func chooseDirectory(for instance: InstanceConfig) {
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

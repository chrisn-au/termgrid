import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var config: ConfigManager
    @State private var selectedInstanceId: String?

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Instances")
                    .font(.headline)
                    .padding(.horizontal)

                List(config.appConfig.instances, selection: $selectedInstanceId) { instance in
                    Text(instance.name)
                        .tag(instance.id)
                }

                HStack(spacing: 8) {
                    Button(action: addInstance) {
                        Label("Add", systemImage: "plus")
                    }

                    Button(action: deleteSelected) {
                        Label("Delete", systemImage: "minus")
                    }
                    .disabled(selectedInstanceId == nil)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .frame(minWidth: 150)

            Divider()

            if let id = selectedInstanceId,
               let instance = config.instance(for: id) {
                InstanceEditView(instance: instance, config: config)
                    .id(id)
            } else {
                VStack {
                    Text("Select an instance to edit")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func addInstance() {
        let newInstance = config.addInstance()
        selectedInstanceId = newInstance.id
    }

    private func deleteSelected() {
        if let id = selectedInstanceId {
            config.deleteInstance(id: id)
            selectedInstanceId = nil
        }
    }
}

struct InstanceEditView: View {
    @State var instance: InstanceConfig
    @ObservedObject var config: ConfigManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Instance")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name").font(.subheadline).foregroundColor(.secondary)
                    TextField("Name", text: $instance.name)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: instance.name) {
                            config.updateInstance(instance)
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Working Directory").font(.subheadline).foregroundColor(.secondary)
                    HStack {
                        TextField("Directory", text: $instance.directory)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: instance.directory) {
                                config.updateInstance(instance)
                            }

                        Button("Browse...") {
                            browseDirectory()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Layout").font(.subheadline).foregroundColor(.secondary)
                    Picker("", selection: Binding(
                        get: { instance.resolvedLayoutMode },
                        set: { newMode in
                            instance.layoutMode = newMode
                            config.updateInstance(instance)
                        }
                    )) {
                        Text("Split").tag(LayoutMode.split)
                        Text("Tabs").tag(LayoutMode.tabs)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Font Size").font(.subheadline).foregroundColor(.secondary)
                    Stepper("\(Int(instance.resolvedFontSize))pt", value: Binding(
                        get: { instance.resolvedFontSize },
                        set: { newSize in
                            instance.fontSize = max(8, min(32, newSize))
                            config.updateInstance(instance)
                        }
                    ), in: 8...32)
                    .frame(width: 120)
                }

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rows").font(.subheadline).foregroundColor(.secondary)
                        Stepper("\(instance.rows)", value: $instance.rows, in: 1...10)
                            .onChange(of: instance.rows) {
                                config.updateInstance(instance)
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Columns").font(.subheadline).foregroundColor(.secondary)
                        Stepper("\(instance.cols)", value: $instance.cols, in: 1...10)
                            .onChange(of: instance.cols) {
                                config.updateInstance(instance)
                            }
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func browseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: instance.directory)

        if panel.runModal() == .OK, let url = panel.url {
            instance.directory = url.path
            config.updateInstance(instance)
        }
    }
}

//
//  SettingsView.swift
//  Spello
//
//  设置页面 - 模型选择和App白名单配置
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "qwen2.5:3b"
    @AppStorage("appWhitelist") private var appWhitelistString = ""

    @State private var newAppName = ""
    @Environment(\.dismiss) private var dismiss

    // 可用模型列表
    private let availableModels = [
        "qwen2.5:3b": "Qwen 2.5 (3B) - Fast & Lightweight",
        "llama3.2:3b": "Llama 3.2 (3B) - Balanced",
        "gemma2:2b": "Gemma 2 (2B) - Ultra Lightweight",
        "qwen2.5:7b": "Qwen 2.5 (7B) - High Quality"
    ]

    var appWhitelist: [String] {
        get {
            appWhitelistString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        set {
            appWhitelistString = newValue.joined(separator: ",")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.title.weight(.bold))
                    Text("Configure translation model and app whitelist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Model Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Translation Model", systemImage: "cpu")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Select the AI model for translation")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Model", selection: $selectedModel) {
                            ForEach(Array(availableModels.keys.sorted()), id: \.self) { key in
                                Text(availableModels[key] ?? key)
                                    .tag(key)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(12)

                    // App Whitelist Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("App Whitelist", systemImage: "checklist")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Only monitor these apps (leave empty to monitor all apps)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Add new app
                        HStack {
                            TextField("Enter app name (e.g., Safari)", text: $newAppName)
                                .textFieldStyle(.roundedBorder)

                            Button("Add") {
                                addApp()
                            }
                            .disabled(newAppName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        // App list
                        if !appWhitelist.isEmpty {
                            VStack(spacing: 6) {
                                ForEach(appWhitelist, id: \.self) { app in
                                    HStack {
                                        Image(systemName: "app.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)

                                        Text(app)
                                            .font(.body)

                                        Spacer()

                                        Button(action: { removeApp(app) }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("Monitoring all apps")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(12)
                }
                .padding(24)
            }
        }
        .frame(width: 500, height: 500)
    }

    private func addApp() {
        let trimmed = newAppName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !appWhitelist.contains(trimmed) else { return }

        var current = appWhitelist
        current.append(trimmed)
        appWhitelistString = current.joined(separator: ",")
        newAppName = ""
    }

    private func removeApp(_ app: String) {
        var current = appWhitelist
        current.removeAll { $0 == app }
        appWhitelistString = current.joined(separator: ",")
    }
}

#Preview {
    SettingsView()
}

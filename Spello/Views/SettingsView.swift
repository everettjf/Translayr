//
//  SettingsView.swift
//  Spello
//
//  设置页面 - 使用 NavigationSplitView 架构
//

import SwiftUI

// MARK: - Settings Section Enum

enum PreferencesSection: String, CaseIterable, Identifiable {
    case general = "General"
    case models = "Models"
    case skipApps = "Skip Apps"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .models: return "cpu"
        case .skipApps: return "app.badge.xmark"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Main Settings Window

struct SettingsView: View {
    @State private var selection: PreferencesSection? = .general
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(PreferencesSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .frame(minWidth: 180)
        } detail: {
            // Detail content
            Group {
                switch selection {
                case .general:
                    GeneralSettingsView()
                case .models:
                    ModelsSettingsView()
                case .skipApps:
                    SkipAppsSettingsView()
                case .about:
                    AboutView()
                case .none:
                    Text("Select a section from the sidebar")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 480)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("autoLaunchAtLogin") private var autoLaunch = false
    @AppStorage("showNotifications") private var showNotifications = true

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Launch at login", isOn: $autoLaunch)
                    .disabled(true) // TODO: Implement launch at login

                Toggle("Show notifications", isOn: $showNotifications)
                    .disabled(true) // TODO: Implement notifications
            }

            Section("Performance") {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Translation requests are processed locally using Ollama")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("General")
    }
}

// MARK: - Models Settings

struct ModelsSettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "qwen2.5:3b"

    // 可用模型列表
    private let availableModels: [(key: String, value: String)] = [
        ("qwen2.5:3b", "Qwen 2.5 (3B) - Fast & Lightweight"),
        ("llama3.2:3b", "Llama 3.2 (3B) - Balanced"),
        ("gemma2:2b", "Gemma 2 (2B) - Ultra Lightweight"),
        ("qwen2.5:7b", "Qwen 2.5 (7B) - High Quality")
    ]

    var body: some View {
        Form {
            Section {
                Text("Select the AI model for Chinese to English translation")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Section("Available Models") {
                Picker("Default model", selection: $selectedModel) {
                    ForEach(availableModels, id: \.key) { model in
                        Text(model.value)
                            .tag(model.key)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            Section {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ollama Required")
                            .font(.callout.weight(.medium))
                        Text("Make sure Ollama is running and the selected model is installed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Models")
    }
}

// MARK: - Skip Apps Settings

struct SkipAppsSettingsView: View {
    @AppStorage("appSkipList") private var appSkipListString = ""
    @State private var newAppName = ""

    var appSkipList: [String] {
        get {
            appSkipListString.split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        set {
            appSkipListString = newValue.joined(separator: ",")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Skip Apps")
                    .font(.title2.weight(.bold))
                Text("Skip translation service for these applications")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()

            // Add new app
            HStack {
                TextField("Enter app name (e.g., Terminal, Xcode)", text: $newAppName)
                    .textFieldStyle(.roundedBorder)

                Button(action: addApp) {
                    Label("Add", systemImage: "plus")
                }
                .disabled(newAppName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            // App list
            if !appSkipList.isEmpty {
                List {
                    ForEach(appSkipList, id: \.self) { app in
                        HStack {
                            Label(app, systemImage: "app.fill")
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: { removeApp(app) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.inset)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("Monitoring All Apps")
                        .font(.headline)

                    Text("No apps in skip list. Translation is active for all applications.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer()
        }
        .navigationTitle("Skip Apps")
    }

    private func addApp() {
        let trimmed = newAppName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !appSkipList.contains(trimmed) else { return }

        var current = appSkipList
        current.append(trimmed)
        appSkipListString = current.joined(separator: ",")
        newAppName = ""
    }

    private func removeApp(_ app: String) {
        var current = appSkipList
        current.removeAll { $0 == app }
        appSkipListString = current.joined(separator: ",")
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            Image(systemName: "character.textbox")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // App Name and Version
            VStack(spacing: 8) {
                Text("Spello")
                    .font(.largeTitle.weight(.bold))

                Text("Version 1.0.0")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Description
            VStack(spacing: 12) {
                Text("Intelligent Chinese Translation Assistant")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Automatically detects and translates Chinese text\nin other applications using local AI models")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            Divider()
                .padding(.horizontal, 60)

            // Tech Stack
            VStack(spacing: 8) {
                HStack(spacing: 20) {
                    TechBadge(icon: "swift", text: "Swift")
                    TechBadge(icon: "cpu", text: "Ollama")
                    TechBadge(icon: "eye", text: "Accessibility")
                }

                Text("© 2025 Spello. All rights reserved.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("About")
    }
}

// MARK: - Supporting Views

struct TechBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
            Text(text)
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

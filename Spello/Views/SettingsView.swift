//
//  SettingsView.swift
//  Spello
//
//  设置页面 - 使用 NavigationSplitView 架构
//

import SwiftUI
import Ollama

// MARK: - Settings Section Enum

enum PreferencesSection: String, CaseIterable, Identifiable {
    case general = "General"
    case language = "Language"
    case models = "Models"
    case skipApps = "Skip Apps"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .language: return "globe"
        case .models: return "cpu"
        case .skipApps: return "eraser"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Main Settings Window

struct SettingsView: View {
    @State private var selection: PreferencesSection? = .general

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(PreferencesSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("Spello")
            .frame(minWidth: 180)
        } detail: {
            // Detail content
            switch selection {
            case .general:
                GeneralSettingsView()
            case .language:
                LanguageSettingsView()
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
        .frame(minWidth: 720, minHeight: 480)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @StateObject private var accessibilityMonitor = AccessibilityMonitor.shared
    @StateObject private var spellCheckMonitor = SpellCheckMonitor.shared

    @State private var hasAccessibilityPermission = false
    @State private var showingPermissionAlert = false
    @State private var permissionCheckTimer: Timer?

    var body: some View {
        Form {
            Section("Status") {
                // Monitoring Status
                HStack {
                    Label("Monitoring Status", systemImage: accessibilityMonitor.isMonitoring ? "waveform.circle.fill" : "waveform.circle")
                        .foregroundColor(accessibilityMonitor.isMonitoring ? .green : .secondary)

                    Spacer()

                    Text(accessibilityMonitor.isMonitoring ? "Active" : "Inactive")
                        .font(.callout.weight(.medium))
                        .foregroundColor(accessibilityMonitor.isMonitoring ? .green : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(accessibilityMonitor.isMonitoring ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
                        )
                }

                // Accessibility Permission Status
                HStack {
                    Label("Accessibility Permission", systemImage: hasAccessibilityPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundColor(hasAccessibilityPermission ? .blue : .orange)

                    Spacer()

                    if hasAccessibilityPermission {
                        Text("Granted")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.15))
                            )
                    } else {
                        Button("Grant Permission") {
                            requestAccessibilityPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                if !hasAccessibilityPermission {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                            .font(.callout)

                        Text("Accessibility permission is required to monitor text in other applications")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Section("Performance") {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.callout)

                    Text("Translation requests are processed locally using Ollama")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("General")
        .onAppear {
            checkAccessibilityPermission()
            startSystemWideMonitoring()

            // Start timer to periodically check permission status
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task { @MainActor in
                    checkAccessibilityPermission()
                    // Auto-start monitoring when permission is granted
                    if hasAccessibilityPermission && !accessibilityMonitor.isMonitoring {
                        startSystemWideMonitoring()
                    }
                }
            }
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
        }
        .alert("Accessibility Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open System Settings") {
                openSystemPreferences()
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("Spello needs accessibility permission to monitor text input in other apps.\n\nPlease go to:\nSystem Settings → Privacy & Security → Accessibility\n\nand enable Spello.")
        }
    }

    private func checkAccessibilityPermission() {
        hasAccessibilityPermission = accessibilityMonitor.checkAccessibilityPermission()
    }

    private func requestAccessibilityPermission() {
        accessibilityMonitor.requestAccessibilityPermission()
        showingPermissionAlert = true
    }

    private func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startSystemWideMonitoring() {
        if hasAccessibilityPermission {
            accessibilityMonitor.startMonitoring()
            spellCheckMonitor.startMonitoring()
        }
    }
}

// MARK: - Language Settings

struct LanguageSettingsView: View {
    @State private var selectedLanguage = LanguageConfig.detectionLanguage

    var body: some View {
        Form {
            Section {
                Text("Select which language Spello should detect and translate")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Section("Detection Language") {
                Picker("Language to detect", selection: $selectedLanguage) {
                    ForEach(DetectionLanguage.allCases) { language in
                        HStack {
                            Text(language.displayName)
                            Spacer()
                        }
                        .tag(language)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .onChange(of: selectedLanguage) { newLanguage in
                    LanguageConfig.detectionLanguage = newLanguage
                }
            }

            Section("How It Works") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detection")
                                .font(.callout.weight(.semibold))
                            Text("Spello monitors text in other applications and detects \(selectedLanguage.displayName) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Translation")
                                .font(.callout.weight(.semibold))
                            Text("Detected text is translated to \(selectedLanguage.targetLanguage) using your selected AI model")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Underline & Click")
                                .font(.callout.weight(.semibold))
                            Text("Detected text is underlined. Click to see the translation in a popup")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Language")
    }
}

// MARK: - Models Settings

struct ModelsSettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "qwen2.5:3b"
    @State private var availableModels: [Ollama.Client.ListModelsResponse.Model] = []
    @State private var isLoadingModels = false
    @State private var modelLoadError: String?
    @State private var isPullingModel = false
    @State private var pullStatusMessage: String?
    @State private var pullStatusIsError = false
    @State private var currentPullModelName: String?

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private let recommendedStarterModel = "qwen2.5:3b"

    var body: some View {
        let hasLocalModels = !availableModels.isEmpty

        Form {
            Section {
                Text("Select the AI model for Chinese to English translation")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Section("Available Models") {
                if isLoadingModels {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Loading models…")
                    }
                    .padding(.vertical, 4)
                } else if let modelLoadError {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Unable to load models", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(modelLoadError)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button {
                            Task { await refreshModels(force: true) }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isLoadingModels || isPullingModel)
                    }
                } else if availableModels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No local models detected")
                            .font(.callout.weight(.medium))
                        Text("Run `ollama pull <model>` to install a model, then refresh.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Download \(recommendedStarterModel) to get started quickly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button {
                            Task { await refreshModels(force: true) }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isLoadingModels || isPullingModel)

                        if !availableModels.contains(where: { $0.name == recommendedStarterModel }) {
                            Button {
                                Task { await pullModel(named: recommendedStarterModel) }
                            } label: {
                                Label("Download \(recommendedStarterModel)", systemImage: "arrow.down.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(isLoadingModels || isPullingModel)
                        }
                    }
                } else {
                    Picker("Default model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.name) { model in
                            Text(displayName(for: model))
                                .tag(model.name)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()

                    HStack(spacing: 12) {
                        Button {
                            Task { await refreshModels(force: true) }
                        } label: {
                            Label("Refresh Models", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isLoadingModels || isPullingModel)

                        if !availableModels.contains(where: { $0.name == selectedModel }) {
                            Button {
                                Task { await pullModel(named: selectedModel) }
                            } label: {
                                Label("Download \(selectedModel)", systemImage: "arrow.down.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(isLoadingModels || isPullingModel)
                        }
                    }
                }
            }

            Section("Ollama Setup") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: hasLocalModels ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(hasLocalModels ? .green : .orange)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hasLocalModels ? "Ollama Installed" : "Ollama Required")
                                .font(.callout.weight(.medium))
                            Text("Make sure Ollama is running and the selected model is installed. Ollama runs the local models used for translation.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Link(destination: URL(string: "https://ollama.com")!) {
                                Text("https://ollama.com")
                            }
                            if isPullingModel {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Downloading \(currentPullModelName ?? "model")…")
                                        .font(.caption.weight(.medium))
                                }
                            } else if let pullStatusMessage {
                                Text(pullStatusMessage)
                                    .font(.caption)
                                    .foregroundColor(pullStatusIsError ? .red : .green)
                            }
                        }
                    }

                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Models")
        .task {
            await refreshModels()
        }
    }

    @MainActor
    private func refreshModels(force: Bool = false) async {
        if isLoadingModels && !force {
            return
        }

        isLoadingModels = true
        modelLoadError = nil

        defer { isLoadingModels = false }

        do {
            guard let hostURL = URL(string: "\(OllamaConfig.host):\(OllamaConfig.port)") else {
                modelLoadError = "Invalid Ollama host configuration."
                return
            }

            let client = Ollama.Client(host: hostURL)
            let response = try await client.listModels()
            let models = response.models.sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }

            availableModels = models

            if let firstModel = models.first,
               models.contains(where: { $0.name == selectedModel }) == false {
                selectedModel = firstModel.name
            }

            modelLoadError = nil
        } catch {
            if let clientError = error as? Ollama.Client.Error {
                modelLoadError = clientError.description
            } else {
                modelLoadError = error.localizedDescription
            }
            print("⚠️ Failed to fetch models: \(error)")
        }
    }

    @MainActor
    private func pullModel(named name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isPullingModel else { return }

        guard let hostURL = URL(string: "\(OllamaConfig.host):\(OllamaConfig.port)") else {
            pullStatusMessage = "Invalid Ollama host configuration."
            pullStatusIsError = true
            return
        }

        guard let modelID = Ollama.Model.ID(rawValue: trimmed) else {
            pullStatusMessage = "Invalid model identifier: \(trimmed)."
            pullStatusIsError = true
            return
        }

        isPullingModel = true
        currentPullModelName = trimmed
        pullStatusMessage = "Downloading \(trimmed)…"
        pullStatusIsError = false
        modelLoadError = nil

        defer {
            isPullingModel = false
            currentPullModelName = nil
        }

        do {
            let client = Ollama.Client(host: hostURL)
            let success = try await client.pullModel(modelID)

            if success {
                await refreshModels(force: true)
                if availableModels.contains(where: { $0.name == trimmed }) {
                    selectedModel = trimmed
                }
                pullStatusMessage = "Model \(trimmed) downloaded successfully."
                pullStatusIsError = false
            } else {
                pullStatusMessage = "Failed to download \(trimmed)."
                pullStatusIsError = true
            }
        } catch {
            let message: String
            if let clientError = error as? Ollama.Client.Error {
                message = clientError.description
            } else {
                message = error.localizedDescription
            }
            pullStatusMessage = message
            pullStatusIsError = true
            print("⚠️ Failed to pull model \(trimmed): \(error)")
        }
    }

    private func displayName(for model: Ollama.Client.ListModelsResponse.Model) -> String {
        var components: [String] = []

        components.append(model.name)

        let sizeString = Self.byteFormatter.string(fromByteCount: model.size)
        components.append(sizeString)

        if let date = Self.isoFormatter.date(from: model.modifiedAt) {
            let relativeDate = Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
            components.append(relativeDate)
        }

        return components.joined(separator: " • ")
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

//
//  ShortcutsSettingsView.swift
//  Translayr
//
//  快捷键设置视图
//

import SwiftUI
import AppKit

struct ShortcutsSettingsView: View {
    @AppStorage("isTranslayrEnabled") private var isTranslayrEnabled = true
    @AppStorage("globalShortcutEnabled") private var globalShortcutEnabled = false

    @State private var shortcut: KeyboardShortcutPreference? = loadShortcut()
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        Form {
            Section {
                Text("Configure a global keyboard shortcut to quickly enable or disable Translayr")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Section("Global Shortcut") {
                Toggle("Enable Global Shortcut", isOn: $globalShortcutEnabled)
                    .onChange(of: globalShortcutEnabled) { oldValue, newValue in
                        if newValue {
                            if let shortcut = shortcut {
                                registerShortcut(shortcut)
                            }
                        } else {
                            GlobalShortcutCenter.shared.unregister()
                        }
                    }

                if globalShortcutEnabled {
                    HStack(spacing: 12) {
                        Text("Shortcut:")
                            .foregroundColor(.secondary)

                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            HStack {
                                if isRecording {
                                    HStack(spacing: 6) {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .controlSize(.small)
                                        Text("Press keys...")
                                            .foregroundColor(.secondary)
                                    }
                                } else if let shortcut = shortcut {
                                    Text(shortcut.displayString)
                                        .font(.system(.body, design: .monospaced))
                                } else {
                                    Text("Click to record")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(minWidth: 120)
                        }
                        .buttonStyle(.bordered)

                        if shortcut != nil && !isRecording {
                            Button(action: {
                                clearShortcut()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Current function: Toggle Translayr on/off")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Current Status") {
                HStack {
                    Text("Translayr is currently:")
                    Spacer()
                    Text(isTranslayrEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(isTranslayrEnabled ? .green : .secondary)
                        .fontWeight(.medium)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Shortcuts")
        .onAppear {
            if globalShortcutEnabled, let shortcut = shortcut {
                registerShortcut(shortcut)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .keyDown {
                let keyCode = Int(event.keyCode)
                let modifiers = event.modifierFlags.toShortcutModifiers()

                // 至少需要一个修饰键
                if !modifiers.isEmpty {
                    let newShortcut = KeyboardShortcutPreference(keyCode: keyCode, modifiers: modifiers)
                    self.shortcut = newShortcut
                    saveShortcut(newShortcut)

                    if globalShortcutEnabled {
                        registerShortcut(newShortcut)
                    }

                    stopRecording()
                    return nil // 阻止事件传播
                }
            }
            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func clearShortcut() {
        shortcut = nil
        UserDefaults.standard.removeObject(forKey: "globalShortcut")
        GlobalShortcutCenter.shared.unregister()
    }

    private func registerShortcut(_ shortcut: KeyboardShortcutPreference) {
        GlobalShortcutCenter.shared.register(shortcut: shortcut) {
            Task { @MainActor in
                isTranslayrEnabled.toggle()
            }
        }
    }

    private static func loadShortcut() -> KeyboardShortcutPreference? {
        guard let data = UserDefaults.standard.data(forKey: "globalShortcut"),
              let shortcut = try? JSONDecoder().decode(KeyboardShortcutPreference.self, from: data) else {
            return nil
        }
        return shortcut
    }

    private func saveShortcut(_ shortcut: KeyboardShortcutPreference) {
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: "globalShortcut")
        }
    }
}

private extension NSEvent.ModifierFlags {
    func toShortcutModifiers() -> KeyboardShortcutPreference.ModifierFlags {
        var flags = KeyboardShortcutPreference.ModifierFlags()
        if contains(.command) { flags.insert(.command) }
        if contains(.option) { flags.insert(.option) }
        if contains(.control) { flags.insert(.control) }
        if contains(.shift) { flags.insert(.shift) }
        return flags
    }
}

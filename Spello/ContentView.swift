//
//  ContentView.swift
//  Spello
//
//  Created by eevv on 9/28/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var spellService = SpellService()
    @StateObject private var accessibilityMonitor = AccessibilityMonitor.shared
    @StateObject private var spellCheckMonitor = SpellCheckMonitor.shared

    @State private var text = """
    美国数十年来主导全球科技市场。但中国想要改变这一点。

    这个世界第二大经济体正投入大量资金于人工智能（AI）和机器人技术。至关重要的是，北京也在大力投资生产驱动这些尖端技术的高阶晶片（芯片）。

    上个月，总部位于矽谷的AI晶片巨头英伟达（Nvidia，辉达）的老板黄仁勋警告称，中国在晶片开发方面仅比美国“落后几纳秒”。

    💡 Spello monitors text input in real-time and provides translations!
    """
    @State private var isAutomaticSpellingCorrectionEnabled = true
    @State private var selectedLanguage: String? = nil
    @State private var hasAccessibilityPermission = false
    @State private var showingPermissionAlert = false

    private let availableLanguages = [
        "en_US": "English (US)",
        "en_GB": "English (UK)",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "pt": "Portuguese",
        "zh_Hans": "Chinese (Simplified)"
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Text editor
            SpellCheckedTextView(
                text: $text,
                isAutomaticSpellingCorrectionEnabled: $isAutomaticSpellingCorrectionEnabled,
                selectedLanguage: $selectedLanguage
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // System-wide monitoring status section
            VStack(spacing: 8) {
                HStack {
                    // Monitoring status indicator
                    HStack(spacing: 6) {
                        Image(systemName: accessibilityMonitor.isMonitoring ? "circle.fill" : "circle")
                            .foregroundColor(accessibilityMonitor.isMonitoring ? .green : .secondary)
                            .font(.caption)
                        Text(accessibilityMonitor.isMonitoring ? "Monitoring Active" : "Monitoring Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Permission status indicator
                    HStack(spacing: 4) {
                        Image(systemName: hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(hasAccessibilityPermission ? .green : .orange)
                        Text(hasAccessibilityPermission ? "Accessibility Granted" : "Accessibility Required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !hasAccessibilityPermission {
                        Button("Grant Permission") {
                            requestAccessibilityPermission()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Status bar
            HStack {
                Text("Characters: \(text.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            // Set up initial spell checking
            NSSpellChecker.shared.automaticallyIdentifiesLanguages = true
            // Check accessibility permission status
            checkAccessibilityPermission()
            // Try to start monitoring if we have permission
            startSystemWideMonitoring()
            // Start timer to periodically check permission status
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                checkAccessibilityPermission()
                // Auto-start monitoring when permission is granted
                if hasAccessibilityPermission && !accessibilityMonitor.isMonitoring {
                    startSystemWideMonitoring()
                }
            }
        }
        .alert("Accessibility Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open System Preferences") {
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
        // Open Accessibility settings pane
        // Reference: https://jano.dev/apple/macos/swift/2025/01/08/Accessibility-Permission.html
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startSystemWideMonitoring() {
        if hasAccessibilityPermission {
            accessibilityMonitor.startMonitoring()
            spellCheckMonitor.startMonitoring()
        } else {
            requestAccessibilityPermission()
        }
    }
}

#Preview {
    ContentView()
}

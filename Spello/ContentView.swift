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
            // Header with gradient
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spello")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("智能中文翻译助手")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Status badges
                    HStack(spacing: 12) {
                        StatusBadge(
                            icon: accessibilityMonitor.isMonitoring ? "waveform.circle.fill" : "waveform.circle",
                            text: accessibilityMonitor.isMonitoring ? "监控中" : "未激活",
                            color: accessibilityMonitor.isMonitoring ? .green : .gray,
                            isActive: accessibilityMonitor.isMonitoring
                        )

                        StatusBadge(
                            icon: hasAccessibilityPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                            text: hasAccessibilityPermission ? "已授权" : "需授权",
                            color: hasAccessibilityPermission ? .blue : .orange,
                            isActive: hasAccessibilityPermission
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                if !hasAccessibilityPermission {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)

                        Text("需要辅助功能权限才能监控其他应用的文本")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: requestAccessibilityPermission) {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.raised.fill")
                                Text("授予权限")
                            }
                            .font(.callout.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(NSColor.controlBackgroundColor),
                        Color(NSColor.controlBackgroundColor).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Divider()

            // Text editor with better styling
            SpellCheckedTextView(
                text: $text,
                isAutomaticSpellingCorrectionEnabled: $isAutomaticSpellingCorrectionEnabled,
                selectedLanguage: $selectedLanguage
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(20)

            Divider()

            // Footer with statistics
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "character.cursor.ibeam")
                        .foregroundColor(.blue)
                        .font(.callout)
                    Text("\(text.count) 字符")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 12)

                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.purple)
                        .font(.callout)
                    Text("\(text.split(separator: "\n").count) 行")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Powered by Ollama")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(minWidth: 900, minHeight: 650)
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

// MARK: - Status Badge Component

struct StatusBadge: View {
    let icon: String
    let text: String
    let color: Color
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(color)
                .symbolEffect(.pulse, options: .repeating, value: isActive)

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ContentView()
}

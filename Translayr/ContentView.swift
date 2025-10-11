//
//  ContentView.swift
//  Translayr
//
//  Created by XNU on 9/28/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var spellService = SpellService()
    @StateObject private var accessibilityMonitor = AccessibilityMonitor.shared
    @StateObject private var spellCheckMonitor = SpellCheckMonitor.shared

    @State private var hasAccessibilityPermission = false
    @State private var showingPermissionAlert = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Translayr")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Intelligent Translation Assistant")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Status badges and settings button
                    HStack(spacing: 12) {
                        StatusBadge(
                            icon: accessibilityMonitor.isMonitoring ? "waveform.circle.fill" : "waveform.circle",
                            text: accessibilityMonitor.isMonitoring ? "Enabled" : "Inactive",
                            color: accessibilityMonitor.isMonitoring ? .green : .gray,
                            isActive: accessibilityMonitor.isMonitoring
                        )

                        StatusBadge(
                            icon: hasAccessibilityPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                            text: hasAccessibilityPermission ? "Authorized" : "Needs Permission",
                            color: hasAccessibilityPermission ? .blue : .orange,
                            isActive: hasAccessibilityPermission
                        )

                        // Settings button
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                if !hasAccessibilityPermission {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)

                        Text("Accessibility permission needed to monitor text in other apps")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: requestAccessibilityPermission) {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.raised.fill")
                                Text("Grant Permission")
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

            // 主内容区域 - 显示监控状态信息
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("Real-time Translation Monitor")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)

                    Text("Automatically detects and translates Chinese text in other apps")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
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
                Task { @MainActor in
                    checkAccessibilityPermission()
                    // Auto-start monitoring when permission is granted
                    if hasAccessibilityPermission && !accessibilityMonitor.isMonitoring {
                        startSystemWideMonitoring()
                    }
                }
            }
        }
        .alert("Accessibility Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open System Preferences") {
                openSystemPreferences()
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("Translayr needs accessibility permission to monitor text input in other apps.\n\nPlease go to:\nSystem Settings → Privacy & Security → Accessibility\n\nand enable Translayr.")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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

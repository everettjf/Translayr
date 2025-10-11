//
//  GeneralSettingsView.swift
//  Translayr
//
//  Created by eevv on 10/10/25.
//


import SwiftUI
import Ollama

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
            Text("Translayr needs accessibility permission to monitor text input in other apps.\n\nPlease go to:\nSystem Settings → Privacy & Security → Accessibility\n\nand enable Translayr.")
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
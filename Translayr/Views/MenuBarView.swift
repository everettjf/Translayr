import SwiftUI
import AppKit

/// 菜单栏视图：展示监控状态以及常用操作
struct MenuBarView: View {
    @ObservedObject var accessibilityMonitor: AccessibilityMonitor
    @AppStorage("isTranslayrEnabled") private var isTranslayrEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusSection
            Divider()
            enableToggle
            Divider()
            controlButtons
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(minWidth: 200)
    }

    private var statusSection: some View {
        HStack(spacing: 8) {
            Text(accessibilityMonitor.isMonitoring ? "Status: Active" : "Status: Inactive")
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
    }

    private var enableToggle: some View {
        Toggle(isOn: $isTranslayrEnabled) {
            Label("Enable Translayr", systemImage: isTranslayrEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isTranslayrEnabled ? .green : .secondary)
        }
        .toggleStyle(.switch)
        .onChange(of: isTranslayrEnabled) { oldValue, newValue in
            if newValue {
                SpellCheckMonitor.shared.startMonitoring()
            } else {
                SpellCheckMonitor.shared.stopMonitoring()
                OverlayWindowManager.shared.hideAll()
                OverlayWindowManager.shared.closeTranslationPopup()
            }
        }
    }

    private var controlButtons: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                openMainWindow()
            } label: {
                Label("Open Main Window", systemImage: "rectangle.and.text.magnifyingglass")
            }

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Quit Translayr", systemImage: "power")
            }
        }
        .buttonStyle(.plain)
    }

    private func openMainWindow() {
        AppDelegate.shared?.openMainWindow()
    }
}

#Preview("MenuBar Active") {
    MenuBarView(accessibilityMonitor: AccessibilityMonitor.shared)
}

import SwiftUI
import AppKit

/// 菜单栏视图：展示监控状态以及常用操作
struct MenuBarView: View {
    @ObservedObject var accessibilityMonitor: AccessibilityMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusSection
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

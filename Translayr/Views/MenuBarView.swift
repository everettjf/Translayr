import SwiftUI
import AppKit

/// 菜单栏视图：展示监控状态以及常用操作
struct MenuBarView: View {
    @ObservedObject var accessibilityMonitor: AccessibilityMonitor
    @AppStorage("isTranslayrEnabled") private var isTranslayrEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusSection
            enableButton
            Divider()
            controlButtons
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(minWidth: 250)
    }

    private var statusSection: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isTranslayrEnabled ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)
            Text(isTranslayrEnabled ? "Enabled" : "Disabled")
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
    }

    private var enableButton: some View {
        Button {
            toggleTranslayr()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isTranslayrEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isTranslayrEnabled ? .green : .secondary)
                    .font(.system(size: 16))

                Text(isTranslayrEnabled ? "Disable Translayr" : "Enable Translayr")
                    .font(.body)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.05))
        )
    }

    private func toggleTranslayr() {
        isTranslayrEnabled.toggle()

        if isTranslayrEnabled {
            SpellCheckMonitor.shared.startMonitoring()
        } else {
            SpellCheckMonitor.shared.stopMonitoring()
            OverlayWindowManager.shared.hideAll()
            OverlayWindowManager.shared.closeTranslationPopup()
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

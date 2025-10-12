//
//  TranslayrApp.swift
//  Translayr
//
//  Created by XNU on 9/28/25.
//

import SwiftUI

@main
struct TranslayrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var accessibilityMonitor = AccessibilityMonitor.shared

    var body: some Scene {
        // 主窗口
        Window("Translayr", id: "main") {
            SettingsView()
        }
        .commands {
            // 可以添加自定义菜单命令
        }
        .defaultSize(width: 720, height: 480)

        // 菜单栏图标（苹果官方方法）
        MenuBarExtra("Translayr", systemImage: "character.textbox.badge.sparkles") {
            MenuBarView(accessibilityMonitor: accessibilityMonitor)
        }
        .menuBarExtraStyle(.menu)
    }
}

// App Delegate 用于注册系统服务
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static weak var shared: AppDelegate?
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // 注册系统服务
        _ = SystemServiceProvider.shared
        print("System services registered")

        // 延迟一点获取主窗口并设置代理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupMainWindow()
        }
    }

    private func setupMainWindow() {
        // 找到主窗口并设置代理
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
            mainWindow = window
            window.delegate = self
            print("✅ Main window reference saved")
        }
    }

    // 关闭主窗口时不退出应用（保留在状态栏）
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // 改为 false，关闭窗口后应用继续运行
    }

    // 支持从 Dock 重新激活窗口
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openMainWindow()
        }
        return true
    }

    // 窗口即将关闭时，隐藏而不是关闭
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)  // 隐藏窗口
        return false  // 阻止关闭
    }

    // 打开主窗口的方法
    @objc func openMainWindow() {
        print("📱 Opening main window...")
        NSApp.activate(ignoringOtherApps: true)

        // 如果有保存的窗口引用，使用它
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            print("✅ Main window shown (from saved reference)")
            return
        }

        // 否则查找主窗口
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
            mainWindow = window
            window.delegate = self
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            print("✅ Main window shown (found)")
        } else {
            print("⚠️ No window found")
        }
    }
}

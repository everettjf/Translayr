//
//  StatusBarController.swift
//  Spello
//
//  菜单栏图标控制器 - 管理右上角的状态栏图标和菜单
//

import Cocoa
import SwiftUI

/// 菜单栏图标控制器
/// 功能：
/// 1. 在 macOS 右上角显示状态栏图标
/// 2. 提供菜单：打开主窗口、设置、关于、退出
/// 3. 显示监控状态
@MainActor
class StatusBarController {
    static let shared = StatusBarController()

    /// 状态栏项
    private var statusItem: NSStatusItem?

    /// 菜单
    private var menu: NSMenu?

    /// 监控状态菜单项（用于动态更新）
    private var monitoringStatusMenuItem: NSMenuItem?

    private init() {}

    /// 设置状态栏图标
    func setupStatusBar() {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // 设置图标（使用系统图标）
        if let button = statusItem?.button {
            // 使用文字图标 "Sp"（代表 Spello）
            button.title = "Sp"
            button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        }

        // 创建菜单
        setupMenu()
    }

    /// 创建菜单
    private func setupMenu() {
        menu = NSMenu()

        // 监控状态
        monitoringStatusMenuItem = NSMenuItem(
            title: "监控状态：未激活",
            action: nil,
            keyEquivalent: ""
        )
        monitoringStatusMenuItem?.isEnabled = false
        menu?.addItem(monitoringStatusMenuItem!)

        menu?.addItem(NSMenuItem.separator())

        // 打开主窗口
        let openWindowItem = NSMenuItem(
            title: "打开主窗口",
            action: #selector(openMainWindow),
            keyEquivalent: "o"
        )
        openWindowItem.target = self
        menu?.addItem(openWindowItem)

        menu?.addItem(NSMenuItem.separator())

        // 设置
        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu?.addItem(settingsItem)

        // 关于
        let aboutItem = NSMenuItem(
            title: "关于 Spello",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu?.addItem(aboutItem)

        menu?.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(
            title: "退出 Spello",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu?.addItem(quitItem)

        statusItem?.menu = menu

        // 开始监听监控状态
        observeMonitoringStatus()
    }

    /// 监听监控状态变化
    private func observeMonitoringStatus() {
        // 定期更新监控状态（在主线程上）
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // 使用 Task 确保在主线程上执行
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateMonitoringStatus()
            }
        }
    }

    /// 更新监控状态显示
    private func updateMonitoringStatus() {
        let isMonitoring = AccessibilityMonitor.shared.isMonitoring
        let statusText = isMonitoring ? "✅ 监控状态：已激活" : "⏸ 监控状态：未激活"
        monitoringStatusMenuItem?.title = statusText
    }

    // MARK: - Menu Actions（菜单操作）

    @objc private func openMainWindow() {
        print("📱 Opening main window...")

        // 激活应用
        NSApp.activate(ignoringOtherApps: true)

        // 查找主窗口（排除状态栏和其他系统窗口）
        let mainWindow = NSApp.windows.first { window in
            // 排除 NSPanel 和无标题窗口
            return !(window is NSPanel) &&
                   window.isVisible == false || window.canBecomeMain
        }

        if let window = mainWindow {
            // 显示已有窗口
            window.makeKeyAndOrderFront(nil)
        } else if let window = NSApp.windows.first {
            // 备选：显示第一个窗口
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func openSettings() {
        print("⚙️ Opening settings...")
        // TODO: 实现设置窗口
        showAlert(title: "设置", message: "设置功能即将推出")
    }

    @objc private func showAbout() {
        print("ℹ️ Showing about...")

        let alert = NSAlert()
        alert.messageText = "关于 Spello"
        alert.informativeText = """
        版本：1.0.0

        Spello 是一个智能的中文翻译助手，能够在任何应用中实时检测中文文本并提供 AI 翻译建议。

        功能特性：
        • 系统级文本监控
        • 智能中文检测
        • AI 翻译（基于 Ollama）
        • 浮动下划线提示

        © 2025 eevv
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    @objc private func quitApp() {
        print("👋 Quitting app...")
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}

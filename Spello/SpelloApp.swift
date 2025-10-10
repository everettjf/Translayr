//
//  SpelloApp.swift
//  Spello
//
//  Created by XNU on 9/28/25.
//

import SwiftUI

@main
struct SpelloApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup(makeContent: {
            SettingsView()
        })
        .commands {
            // 可以添加自定义菜单命令
        }
    }
}

// App Delegate 用于注册系统服务
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 注册系统服务
        _ = SystemServiceProvider.shared
        print("System services registered")

        // 设置状态栏图标
        Task { @MainActor in
            StatusBarController.shared.setupStatusBar()
            print("Status bar icon created")
        }
    }

    // 关闭主窗口时不退出应用（保留在状态栏）
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // 改为 false，关闭窗口后应用继续运行
    }

    // 支持从 Dock 重新激活窗口
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // 如果没有可见窗口，显示主窗口
            if let window = NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}

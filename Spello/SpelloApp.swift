//
//  SpelloApp.swift
//  Spello
//
//  Created by eevv on 9/28/25.
//

import SwiftUI

@main
struct SpelloApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup(content: {
            ContentView()
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
    }
}

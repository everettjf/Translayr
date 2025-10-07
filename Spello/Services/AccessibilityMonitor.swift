//
//  AccessibilityMonitor.swift
//  Spello
//
//  监控系统中的文本输入，提供实时拼写检查
//

import Cocoa
import ApplicationServices
import Combine

@MainActor
class AccessibilityMonitor: ObservableObject {
    static let shared = AccessibilityMonitor()

    @Published var currentText: String = ""
    @Published var currentElement: AXUIElement?
    @Published var isMonitoring = false

    private var focusedElement: AXUIElement?
    private var checkTimer: Timer?

    private init() {}

    // MARK: - Accessibility Permission

    /// 检查是否有辅助功能权限（不弹出提示）
    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 请求辅助功能权限（首次会弹出系统提示）
    func requestAccessibilityPermission() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - Monitoring

    /// 开始监控系统文本输入
    func startMonitoring() {
        print("\n🚀 [AccessibilityMonitor] startMonitoring called")

        guard checkAccessibilityPermission() else {
            print("⚠️ [AccessibilityMonitor] Permission not granted")
            requestAccessibilityPermission()
            return
        }

        print("✅ [AccessibilityMonitor] Permission granted, starting monitoring")
        isMonitoring = true

        // 注册通知观察焦点变化
        setupAccessibilityNotifications()

        // 定时检查当前焦点元素的文本
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkFocusedElement()
            }
        }

        print("✅ [AccessibilityMonitor] Timer started")
    }

    /// 停止监控
    func stopMonitoring() {
        print("⏹ Stopping accessibility monitoring")
        isMonitoring = false
        checkTimer?.invalidate()
        checkTimer = nil
        focusedElement = nil
    }

    // MARK: - Private Methods

    private func setupAccessibilityNotifications() {
        // 监听焦点变化
        let systemWide = AXUIElementCreateSystemWide()

        // 注册焦点改变通知
        var observer: AXObserver?
        let pid = ProcessInfo.processInfo.processIdentifier

        let error = AXObserverCreate(pid, { (observer, element, notification, refcon) in
            Task { @MainActor in
                AccessibilityMonitor.shared.handleAccessibilityNotification(element: element, notification: notification)
            }
        }, &observer)

        if error == .success, let observer = observer {
            AXObserverAddNotification(observer, systemWide, kAXFocusedUIElementChangedNotification as CFString, nil)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
    }

    private func handleAccessibilityNotification(element: AXUIElement, notification: CFString) {
        if notification as String == kAXFocusedUIElementChangedNotification {
            focusedElement = element
            checkFocusedElement()
        }
    }

    private func checkFocusedElement() {
        // Get the currently active application
        guard let activeApp = NSWorkspace.shared.frontmostApplication else {
            print("⚠️ [AccessibilityMonitor] No frontmost app")
            return
        }

        let appName = activeApp.localizedName ?? "unknown"
        let pid = activeApp.processIdentifier

        // Skip our own app
        if pid == ProcessInfo.processInfo.processIdentifier {
            return
        }

        let appElement = AXUIElementCreateApplication(pid)

        print("\n🔍 [AccessibilityMonitor] Checking app: \(appName) (PID: \(pid))")

        // Check if we can access ANY attribute from this app
        var attributeNames: CFArray?
        let attrError = AXUIElementCopyAttributeNames(appElement, &attributeNames)
        if attrError == .success {
            if let names = attributeNames as? [String] {
                print("   Available app attributes: \(names.count) - \(names.prefix(5).joined(separator: ", "))")
            }
        } else {
            print("   ⚠️ Cannot even get attribute names from app: error \(attrError.rawValue)")
            print("   This likely means Spello doesn't have proper accessibility access to this app")
            print("   Try: 1) Restart \(appName), 2) Remove and re-add Spello in Accessibility settings")
            return
        }

        // Try multiple approaches to get text

        // Approach 1: Get focused UI element
        var focusedElement: AnyObject?
        let focusError = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        if focusError == .success, let element = focusedElement {
            print("✅ [AccessibilityMonitor] Got focused element")

            let axElement = element as! AXUIElement
            var roleValue: AnyObject?
            AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &roleValue)
            let role = roleValue as? String ?? "unknown"
            print("   Role: \(role)")

            if let text = getTextFromElement(axElement) {
                if text != currentText {
                    print("✅ [AccessibilityMonitor] Text changed in \(appName)")
                    print("   Length: \(text.count)")
                    print("   Preview: \(String(text.prefix(100)))")
                    currentText = text
                    currentElement = axElement
                }
                return
            }
        } else {
            print("⚠️ [AccessibilityMonitor] Cannot get focused element: error \(focusError.rawValue)")
        }

        // Approach 2: Try to get the main window and its text
        var mainWindow: AnyObject?
        let windowError = AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &mainWindow)

        if windowError == .success, let window = mainWindow {
            print("✅ [AccessibilityMonitor] Got main window, trying to get text")

            let axWindow = window as! AXUIElement
            // Try to get focused element from window
            var windowFocused: AnyObject?
            let wFocusErr = AXUIElementCopyAttributeValue(axWindow, kAXFocusedUIElementAttribute as CFString, &windowFocused)

            if wFocusErr == .success, let element = windowFocused {
                let axElement = element as! AXUIElement
                if let text = getTextFromElement(axElement) {
                    if text != currentText {
                        print("✅ [AccessibilityMonitor] Got text from window's focused element")
                        currentText = text
                        currentElement = axElement
                    }
                    return
                }
            }
        } else {
            print("⚠️ [AccessibilityMonitor] Cannot get main window: error \(windowError.rawValue)")
        }

        // Clear if no text found
        if currentText != "" {
            print("⚠️ [AccessibilityMonitor] No text accessible from \(appName)")
            currentText = ""
            currentElement = nil
        }
    }

    private func getTextFromElement(_ element: AXUIElement) -> String? {
        var value: AnyObject?

        // 尝试获取值
        let error = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)

        if error == .success, let text = value as? String {
            print("✅ [AccessibilityMonitor] Got text via AXValue: \(text.count) chars")
            return text
        } else {
            print("⚠️ [AccessibilityMonitor] Failed to get AXValue: \(error.rawValue)")
        }

        // 尝试获取选中的文本
        var selectedText: AnyObject?
        let selectedError = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)

        if selectedError == .success, let text = selectedText as? String {
            print("✅ [AccessibilityMonitor] Got text via AXSelectedText: \(text.count) chars")
            return text
        } else {
            print("⚠️ [AccessibilityMonitor] Failed to get AXSelectedText: \(selectedError.rawValue)")
        }

        // Try to get all available attributes for debugging
        var attributeNames: CFArray?
        let attrError = AXUIElementCopyAttributeNames(element, &attributeNames)
        if attrError == .success, let names = attributeNames as? [String] {
            print("📋 [AccessibilityMonitor] Available attributes: \(names.joined(separator: ", "))")
        }

        return nil
    }

    // MARK: - Text Replacement

    /// 替换当前元素中的文本
    func replaceText(in range: NSRange, with replacement: String) {
        guard let element = currentElement else { return }

        let nsText = currentText as NSString
        let newText = nsText.replacingCharacters(in: range, with: replacement)

        // 设置新文本
        var newValue = newText as CFTypeRef
        let error = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newValue)

        if error == .success {
            currentText = newText
            print("✅ Text replaced successfully")
        } else {
            print("❌ Failed to replace text: \(error.rawValue)")
        }
    }
}

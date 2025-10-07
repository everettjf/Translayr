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

    /// 检查是否有辅助功能权限
    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        return accessEnabled
    }

    /// 请求辅助功能权限
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - Monitoring

    /// 开始监控系统文本输入
    func startMonitoring() {
        guard checkAccessibilityPermission() else {
            print("⚠️ Accessibility permission not granted")
            requestAccessibilityPermission()
            return
        }

        print("✅ Starting accessibility monitoring")
        isMonitoring = true

        // 注册通知观察焦点变化
        setupAccessibilityNotifications()

        // 定时检查当前焦点元素的文本
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkFocusedElement()
            }
        }
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
        // 获取当前系统焦点元素
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?

        let error = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard error == .success, let element = focusedElement else {
            return
        }

        // 获取元素的文本内容
        let axElement = element as! AXUIElement
        if let text = getTextFromElement(axElement) {
            if text != currentText {
                currentText = text
                currentElement = axElement
                print("📝 Text changed: \(text)")
            }
        }
    }

    private func getTextFromElement(_ element: AXUIElement) -> String? {
        var value: AnyObject?

        // 尝试获取值
        let error = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)

        if error == .success, let text = value as? String {
            return text
        }

        // 尝试获取选中的文本
        var selectedText: AnyObject?
        let selectedError = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)

        if selectedError == .success, let text = selectedText as? String {
            return text
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

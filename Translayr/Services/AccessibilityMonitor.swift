//
//  AccessibilityMonitor.swift
//  Translayr
//
//  监控系统中的文本输入，提供实时拼写检查
//

import Cocoa
import ApplicationServices
import Combine

/// 辅助功能监控器 - 负责监控其他应用程序的文本输入
/// 使用 macOS Accessibility API 获取其他应用中的文本内容和位置信息
@MainActor
class AccessibilityMonitor: ObservableObject {
    static let shared = AccessibilityMonitor()

    // MARK: - Published Properties（发布的属性，变化时会通知观察者）

    /// 当前监控的文本内容
    @Published var currentText: String = ""

    /// 当前聚焦的 UI 元素
    @Published var currentElement: AXUIElement?

    /// 是否正在监控
    @Published var isMonitoring = false

    /// 窗口位置是否发生变化（用于触发 overlay 位置更新）
    @Published var windowPositionChanged: Bool = false

    // MARK: - Private Properties（私有属性）

    /// 当前聚焦的元素引用
    private var focusedElement: AXUIElement?

    /// 定时器 - 用于定期检查文本内容
    private var checkTimer: Timer?

    /// 窗口观察者 - 用于监听窗口移动/调整大小事件
    private var windowObserver: AXObserver?

    /// 当前监控的窗口
    private var currentWindow: AXUIElement?

    /// 位置更新定时器 - 定期检查窗口位置（作为通知的备用方案）
    private var positionUpdateTimer: Timer?

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
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let monitor = self else { return }
            Task { @MainActor in
                monitor.checkFocusedElement()
            }
        }

        // 定时检查窗口位置变化（用于更新 overlay 位置）
        positionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let monitor = self else { return }
            Task { @MainActor in
                monitor.checkWindowPosition()
            }
        }

        print("✅ [AccessibilityMonitor] Timers started")
    }

    /// 停止监控
    func stopMonitoring() {
        print("⏹ Stopping accessibility monitoring")
        isMonitoring = false
        checkTimer?.invalidate()
        checkTimer = nil
        positionUpdateTimer?.invalidate()
        positionUpdateTimer = nil
        focusedElement = nil
        currentWindow = nil
        windowObserver = nil
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

        // Check app skip list
        if isAppInSkipList(appName) {
            print("⚠️ [AccessibilityMonitor] App '\(appName)' is in skip list, skipping")
            // Clear current text if we're skipping this app
            if currentText != "" {
                currentText = ""
                currentElement = nil
            }
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
            print("   This likely means Translayr doesn't have proper accessibility access to this app")
            print("   Try: 1) Restart \(appName), 2) Remove and re-add Translayr in Accessibility settings")
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

                    // Update current window for position tracking
                    updateCurrentWindow(for: axElement, pid: pid)
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

                        // Update current window for position tracking
                        updateCurrentWindow(for: axElement, pid: pid)
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

    // MARK: - Text Position（文本位置）

    /// 获取指定文本范围在屏幕上的边界矩形
    /// - Parameter range: 文本范围
    /// - Returns: 屏幕坐标系中的矩形，如果无法获取则返回 nil
    func getBoundsForRange(_ range: NSRange) -> NSRect? {
        guard let element = currentElement else {
            print("⚠️ [AccessibilityMonitor] No current element")
            return nil
        }

        // Create CFRange from NSRange
        let cfRange = CFRange(location: range.location, length: range.length)
        var cfRangeValue = cfRange
        let rangeValue = AXValueCreate(.cfRange, &cfRangeValue)

        // Get bounds for the range
        var boundsValue: AnyObject?
        let error = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue!,
            &boundsValue
        )

        if error == .success, let value = boundsValue {
            var rect = CGRect.zero
            if AXValueGetValue(value as! AXValue, .cgRect, &rect) {
                print("✅ [AccessibilityMonitor] Got bounds for range \(range): \(rect)")

                // 修复：检测异常边界（高度过大可能包含多行或换行符）
                // 总是获取第一个字符的边界作为参考，确保准确性
                if range.length > 0, let firstCharBounds = getBoundsForSingleChar(at: range.location) {
                    // 典型的文本行高在 14-30 像素之间
                    let maxReasonableLineHeight: CGFloat = 35

                    // 情况1：高度异常大（超过阈值）
                    if rect.height > maxReasonableLineHeight {
                        print("⚠️ [AccessibilityMonitor] Detected abnormal height (\(rect.height)), using first char bounds")
                        let fixedRect = NSRect(
                            x: rect.origin.x,
                            y: firstCharBounds.origin.y,
                            width: rect.width,
                            height: firstCharBounds.height
                        )
                        print("✅ [AccessibilityMonitor] Fixed bounds: \(fixedRect)")
                        return fixedRect
                    }

                    // 情况2：Y 坐标偏移过大（可能跨行了）
                    let yOffset = abs(rect.origin.y - firstCharBounds.origin.y)
                    if yOffset > 5 {  // Y 坐标偏移超过 5 像素
                        print("⚠️ [AccessibilityMonitor] Detected Y offset (\(yOffset)), using first char bounds")
                        let fixedRect = NSRect(
                            x: rect.origin.x,
                            y: firstCharBounds.origin.y,
                            width: rect.width,
                            height: firstCharBounds.height
                        )
                        print("✅ [AccessibilityMonitor] Fixed bounds: \(fixedRect)")
                        return fixedRect
                    }

                    // 情况3：高度明显不一致（可能包含了额外的空白）
                    let heightDiff = abs(rect.height - firstCharBounds.height)
                    if heightDiff > 10 {  // 高度差异超过 10 像素
                        print("⚠️ [AccessibilityMonitor] Detected height inconsistency (\(heightDiff)), using first char bounds")
                        let fixedRect = NSRect(
                            x: rect.origin.x,
                            y: firstCharBounds.origin.y,
                            width: rect.width,
                            height: firstCharBounds.height
                        )
                        print("✅ [AccessibilityMonitor] Fixed bounds: \(fixedRect)")
                        return fixedRect
                    }
                }

                return rect
            }
        } else {
            print("⚠️ [AccessibilityMonitor] Failed to get bounds for range: error \(error.rawValue)")
        }

        return nil
    }

    /// 获取单个字符的边界（用于修复异常边界）
    /// - Parameter location: 字符位置
    /// - Returns: 字符的边界矩形，如果无法获取则返回 nil
    private func getBoundsForSingleChar(at location: Int) -> NSRect? {
        guard let element = currentElement else { return nil }

        let cfRange = CFRange(location: location, length: 1)
        var cfRangeValue = cfRange
        guard let rangeValue = AXValueCreate(.cfRange, &cfRangeValue) else { return nil }

        var boundsValue: AnyObject?
        let error = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &boundsValue
        )

        if error == .success, let value = boundsValue {
            var rect = CGRect.zero
            if AXValueGetValue(value as! AXValue, .cgRect, &rect) {
                return rect
            }
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
        let newValue = newText as CFTypeRef
        let error = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newValue)

        if error == .success {
            currentText = newText
            print("✅ Text replaced successfully")
        } else {
            print("❌ Failed to replace text: \(error.rawValue)")
        }
    }

    // MARK: - Window Position Tracking（窗口位置追踪）

    /// 更新当前追踪的窗口，用于监听位置变化
    /// - Parameters:
    ///   - element: UI 元素
    ///   - pid: 应用程序的进程 ID
    private func updateCurrentWindow(for element: AXUIElement, pid: pid_t) {
        // 尝试获取包含此元素的窗口
        var windowValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, kAXWindowAttribute as CFString, &windowValue)

        if error == .success, let window = windowValue as! AXUIElement? {
            // 只在窗口改变时更新
            if currentWindow == nil || !CFEqual(currentWindow, window) {
                print("🪟 [AccessibilityMonitor] Updating tracked window")
                currentWindow = window
                setupWindowNotifications(for: window, pid: pid)
            }
        } else {
            print("⚠️ [AccessibilityMonitor] Could not get window from element")
        }
    }

    /// 设置窗口位置/大小变化的通知监听
    /// - Parameters:
    ///   - window: 要监听的窗口
    ///   - pid: 应用程序的进程 ID
    private func setupWindowNotifications(for window: AXUIElement, pid: pid_t) {
        // Remove old observer if exists
        windowObserver = nil

        // Create new observer for this app
        var observer: AXObserver?
        let error = AXObserverCreate(pid, { (observer, element, notification, refcon) in
            Task { @MainActor in
                AccessibilityMonitor.shared.handleWindowNotification(notification: notification)
            }
        }, &observer)

        if error == .success, let observer = observer {
            // Register for window moved and resized notifications
            AXObserverAddNotification(observer, window, kAXMovedNotification as CFString, nil)
            AXObserverAddNotification(observer, window, kAXResizedNotification as CFString, nil)

            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)

            windowObserver = observer
            print("✅ [AccessibilityMonitor] Window notifications registered")
        } else {
            print("⚠️ [AccessibilityMonitor] Failed to create window observer: \(error.rawValue)")
        }
    }

    /// 处理窗口位置/大小变化的通知
    /// - Parameter notification: 通知类型（移动或调整大小）
    private func handleWindowNotification(notification: CFString) {
        let notificationName = notification as String
        print("🪟 [AccessibilityMonitor] Window notification: \(notificationName)")

        // 切换 windowPositionChanged 的值以触发 overlay 位置更新
        windowPositionChanged.toggle()
    }

    /// 定期检查窗口位置（作为通知机制的备用方案）
    /// 某些应用可能不触发窗口通知，定时检查可以确保位置更新
    private func checkWindowPosition() {
        guard let window = currentWindow, currentElement != nil else {
            return
        }

        // 获取当前窗口位置
        var positionValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)

        if error == .success {
            // 定期触发更新，由 SpellCheckMonitor 决定是否需要更新 overlay
            windowPositionChanged.toggle()
        }
    }

    // MARK: - App Skip List（应用跳过列表）

    /// 检查应用是否在跳过列表中
    /// - Parameter appName: 应用名称
    /// - Returns: 如果应用在跳过列表中返回 true，否则返回 false
    private func isAppInSkipList(_ appName: String) -> Bool {
        let skipListString = UserDefaults.standard.string(forKey: "appSkipList") ?? ""
        let skipList = skipListString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        // If skip list is empty, don't skip any apps
        if skipList.isEmpty || (skipList.count == 1 && skipList[0].isEmpty) {
            return false
        }

        // Check if app is in skip list (case-insensitive)
        return skipList.contains { $0.lowercased() == appName.lowercased() }
    }
}

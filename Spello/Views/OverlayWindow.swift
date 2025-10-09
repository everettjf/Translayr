//
//  OverlayWindow.swift
//  Spello
//
//  透明覆盖窗口 - 在其他应用上方显示下划线
//

import Cocoa
import SwiftUI

/// 透明浮动窗口 - 用于在其他应用上方显示中文文本的下划线
/// 特点：
/// 1. 完全透明，只显示下划线
/// 2. 浮动在所有窗口之上（.floating level）
/// 3. 可以响应鼠标点击但不会抢夺焦点
/// 4. 窗口大小覆盖整个文字区域，便于点击
class OverlayWindow: NSWindow {

    /// 初始化 overlay 窗口
    /// - Parameter frame: 窗口的初始位置和大小
    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Make window transparent
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false

        // Set window level to float above other apps
        self.level = .floating

        // Make window appear on all spaces and above fullscreen apps
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Don't show in window switcher
        self.isMovableByWindowBackground = false

        // Allow mouse events on the window
        self.ignoresMouseEvents = false

        // Make sure window can receive mouse events
        self.acceptsMouseMovedEvents = true
    }

    // Prevent window from becoming key or main
    override var canBecomeKey: Bool {
        return false
    }

    override var canBecomeMain: Bool {
        return false
    }

    /// Update window position and show underline
    func showUnderline(at rect: NSRect, text: String, onClicked: ((String) -> Void)? = nil) {
        // Make the window cover the entire text area for easier clicking
        // But draw the underline at the bottom
        let clickableRect = NSRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height // Use full text height for clickable area
        )

        self.setFrame(clickableRect, display: true)

        // Create or update underline view with full text area
        if let underlineView = self.contentView as? UnderlineView {
            // Update existing view
            underlineView.text = text
            if let onClicked = onClicked {
                underlineView.onClicked = onClicked
            }
            let newSize = NSSize(width: clickableRect.width, height: clickableRect.height)
            if underlineView.frame.size != newSize {
                underlineView.setFrameSize(newSize)
                underlineView.updateTrackingAreas()
            }
            underlineView.needsDisplay = true
        } else {
            // Create new view
            let underlineView = UnderlineView(frame: NSRect(x: 0, y: 0, width: clickableRect.width, height: clickableRect.height))
            underlineView.text = text
            underlineView.onClicked = onClicked
            self.contentView = underlineView
        }

        self.orderFrontRegardless()
    }

    func hide() {
        self.orderOut(nil)
    }
}

/// 下划线视图 - 绘制红色下划线并处理用户交互
/// 功能：
/// 1. 在底部绘制红色下划线
/// 2. 鼠标悬停时显示蓝色高亮背景
/// 3. 鼠标悬停时显示手形指针
/// 4. 响应点击事件以显示翻译弹窗
class UnderlineView: NSView {
    /// 下划线对应的文本内容
    var text: String = ""
    /// 点击回调函数
    var onClicked: ((String) -> Void)?
    /// 是否鼠标悬停中
    private var isHovering = false
    /// 鼠标追踪区域
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTrackingArea()
    }

    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        setupTrackingArea()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            print("🖱️ [UnderlineView] View added to window, text: \(text), callback set: \(onClicked != nil)")
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw semi-transparent highlight when hovering
        if isHovering {
            NSColor.systemBlue.withAlphaComponent(0.1).setFill()
            bounds.fill()
        }

        // Draw red underline at the bottom of the text area
        NSColor.red.setStroke()
        let path = NSBezierPath()

        // Position underline at the very bottom (2 pixels from bottom)
        let underlineY: CGFloat = 2
        path.move(to: NSPoint(x: 0, y: underlineY))
        path.line(to: NSPoint(x: bounds.width, y: underlineY))
        path.lineWidth = 2
        path.stroke()
    }

    override func mouseEntered(with event: NSEvent) {
        print("🖱️ [UnderlineView] Mouse entered: \(text)")
        isHovering = true
        NSCursor.pointingHand.push()
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        print("🖱️ [UnderlineView] Mouse exited: \(text)")
        isHovering = false
        NSCursor.pop()
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        // Handle click - show translation popup
        print("🖱️ [UnderlineView] Mouse down on: \(text)")
        if let callback = onClicked {
            print("🖱️ [UnderlineView] Calling onClicked callback")
            callback(text)
        } else {
            print("⚠️ [UnderlineView] No onClicked callback set!")
        }
    }

    // Accept first mouse to allow clicking without activating window
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    // Make the entire view respond to mouse events
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Return self if point is within bounds, enabling clicks anywhere in the overlay
        return bounds.contains(point) ? self : nil
    }
}

/// Manager for overlay windows
@MainActor
class OverlayWindowManager {
    static let shared = OverlayWindowManager()

    private var overlayWindows: [String: OverlayWindow] = [:]

    /// 当前显示的翻译弹窗（强引用，防止被过早释放导致 crash）
    private var currentTranslationPopup: NSPanel?

    private init() {}

    // MARK: - Public Translation Popup（公共翻译弹窗方法）

    /// 在指定位置显示翻译弹窗（可从任何地方调用）
    /// - Parameters:
    ///   - text: 原文本
    ///   - translations: 翻译候选列表
    ///   - sourceRect: 文本的屏幕位置（Cocoa 坐标系）
    ///   - onSelect: 选择翻译的回调
    func showTranslation(for text: String, translations: [String], at sourceRect: NSRect, onSelect: @escaping (String) -> Void) {
        showTranslationPopup(for: text, translations: translations, near: sourceRect, onSelect: onSelect)
    }

    /// Show underline for a detected text item
    func showUnderline(for item: DetectedTextItem, at bounds: NSRect, element: AXUIElement) {
        let key = "\(item.range.location)-\(item.range.length)"

        // Accessibility API returns coordinates with origin at top-left of main screen
        // macOS window coordinates have origin at bottom-left of main screen
        // So we need to flip the Y coordinate
        guard let mainScreen = NSScreen.main else {
            print("⚠️ Cannot get main screen")
            return
        }

        let screenHeight = mainScreen.frame.height

        // Convert from Accessibility coordinates (top-left origin) to Cocoa coordinates (bottom-left origin)
        // AX Y-coordinate increases downward, Cocoa Y-coordinate increases upward
        let cocoaY = screenHeight - bounds.origin.y - bounds.size.height

        let screenBounds = NSRect(
            x: bounds.origin.x,
            y: cocoaY,
            width: bounds.size.width,
            height: bounds.size.height
        )

        print("🎯 [OverlayWindowManager] Positioning overlay:")
        print("   AX bounds: \(bounds)")
        print("   Screen height: \(screenHeight)")
        print("   Cocoa bounds: \(screenBounds)")

        // Define click handler
        let clickHandler: (String) -> Void = { [weak self] text in
            print("🖱️ [OverlayWindowManager] Click handler triggered for: \(text)")
            Task { @MainActor in
                await self?.handleTextClicked(text, item: item, bounds: screenBounds)
            }
        }

        // Create or update overlay window
        if let window = overlayWindows[key] {
            window.showUnderline(at: screenBounds, text: item.text, onClicked: clickHandler)
        } else {
            let window = OverlayWindow(frame: screenBounds)
            window.showUnderline(at: screenBounds, text: item.text, onClicked: clickHandler)
            overlayWindows[key] = window
        }
    }

    /// Hide all overlay windows
    func hideAll() {
        for window in overlayWindows.values {
            window.hide()
        }
        overlayWindows.removeAll()
    }

    /// Handle clicking on underlined text
    private func handleTextClicked(_ text: String, item: DetectedTextItem, bounds: NSRect) async {
        print("🔄 Getting translations for: \(text)")

        // Get translations from SpellCheckMonitor
        let translations = await SpellCheckMonitor.shared.translateItem(item)

        // Show translation popup near the clicked text
        showTranslationPopup(for: text, translations: translations, near: bounds, onSelect: nil)
    }

    private func showTranslationPopup(for text: String, translations: [String], near textBounds: NSRect, onSelect: ((String) -> Void)? = nil) {
        // 关闭之前的弹窗（如果有）
        currentTranslationPopup?.close()
        currentTranslationPopup = nil

        // 创建翻译弹窗
        let popupWidth: CGFloat = 350
        let popupHeight: CGFloat = 250

        // 计算弹窗位置（在文字下方，增加间距使其更靠下）
        var popupX = textBounds.origin.x
        var popupY = textBounds.origin.y - popupHeight - 30 // 增加间距从 10 到 30

        // 如果弹窗会超出屏幕底部，则显示在文字上方
        if popupY < 50 {
            popupY = textBounds.origin.y + textBounds.size.height + 30
        }

        // 防止弹窗超出屏幕右边缘
        if let screen = NSScreen.main {
            if popupX + popupWidth > screen.frame.maxX {
                popupX = screen.frame.maxX - popupWidth - 10
            }
        }

        // 防止弹窗超出屏幕左边缘
        if popupX < 10 {
            popupX = 10
        }

        let popupFrame = NSRect(x: popupX, y: popupY, width: popupWidth, height: popupHeight)

        // 使用 NSPanel 而不是 NSWindow，并设置为 HUD 样式
        // NSPanel 更适合临时弹窗，失去焦点时会自动隐藏
        let popupPanel = NSPanel(
            contentRect: popupFrame,
            styleMask: [.titled, .nonactivatingPanel],  // 去掉 .closable，使用 nonactivatingPanel
            backing: .buffered,
            defer: false
        )

        popupPanel.title = "Translation: \(text)"
        popupPanel.level = .floating
        popupPanel.isMovableByWindowBackground = true
        popupPanel.hidesOnDeactivate = true  // 失去焦点时自动隐藏

        // 创建 SwiftUI 视图
        let translationsView = TranslationPopupView(
            originalText: text,
            translations: translations,
            onSelect: { [weak self] translation in
                print("✅ Selected translation: \(translation)")

                // 调用外部回调（如果有）
                onSelect?(translation)

                // 关闭弹窗
                self?.currentTranslationPopup?.close()
                self?.currentTranslationPopup = nil
            }
        )

        popupPanel.contentView = NSHostingView(rootView: translationsView)

        // 强引用持有窗口，防止被过早释放
        currentTranslationPopup = popupPanel

        popupPanel.makeKeyAndOrderFront(nil)

        print("🪟 [OverlayWindowManager] Showing popup at \(popupFrame)")
    }
}

// MARK: - Translation Popup View

struct TranslationPopupView: View {
    let originalText: String
    let translations: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Translation")
                        .font(.headline)
                    Text(originalText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Translations list
            if translations.isEmpty {
                VStack {
                    Spacer()
                    Text("Loading translations...")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(translations.enumerated()), id: \.offset) { index, translation in
                            Button(action: {
                                onSelect(translation)
                            }) {
                                HStack(spacing: 12) {
                                    Text(translation)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.blue)
                                        .imageScale(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }

                            if index < translations.count - 1 {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 350, height: 250)
    }
}

//
//  OverlayWindow.swift
//  Translayr
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

        // 窗口透明设置
        self.isOpaque = false              // 窗口不透明度：false = 透明
        self.backgroundColor = .clear       // 背景色：透明
        self.hasShadow = false             // 无阴影

        // 窗口层级：浮动在所有其他应用之上
        self.level = .floating

        // 窗口行为：在所有空间显示，并可在全屏应用上方显示
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 窗口不可通过背景拖动（不会在窗口切换器中显示）
        self.isMovableByWindowBackground = false

        // 允许窗口接收鼠标事件
        self.ignoresMouseEvents = false

        // 确保窗口可以接收鼠标移动事件
        self.acceptsMouseMovedEvents = true
    }

    /// 阻止窗口成为主窗口（防止抢夺其他应用的焦点）
    override var canBecomeKey: Bool {
        return false
    }

    /// 阻止窗口成为主窗口
    override var canBecomeMain: Bool {
        return false
    }

    /// 更新窗口位置并显示下划线
    /// - Parameters:
    ///   - rect: 文本区域的位置和大小（Cocoa 坐标系）
    ///   - text: 要显示下划线的文本内容
    ///   - onClicked: 点击下划线时的回调函数
    ///   - onHovered: 鼠标悬停时的回调函数
    func showUnderline(at rect: NSRect, text: String, onClicked: ((String) -> Void)? = nil, onHovered: ((String) -> Void)? = nil) {
        // 让窗口覆盖整个文本区域，方便用户点击
        // 但下划线只绘制在底部
        let clickableRect = NSRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height // 使用完整的文本高度作为可点击区域
        )

        // 设置窗口位置和大小
        self.setFrame(clickableRect, display: true)

        // 创建或更新下划线视图
        if let underlineView = self.contentView as? UnderlineView {
            // 更新已存在的视图
            underlineView.text = text
            if let onClicked = onClicked {
                underlineView.onClicked = onClicked
            }
            if let onHovered = onHovered {
                underlineView.onHovered = onHovered
            }
            let newSize = NSSize(width: clickableRect.width, height: clickableRect.height)
            if underlineView.frame.size != newSize {
                underlineView.setFrameSize(newSize)
                underlineView.updateTrackingAreas() // 更新鼠标追踪区域
            }
            underlineView.needsDisplay = true // 标记需要重绘
        } else {
            // 创建新视图
            let underlineView = UnderlineView(frame: NSRect(x: 0, y: 0, width: clickableRect.width, height: clickableRect.height))
            underlineView.text = text
            underlineView.onClicked = onClicked
            underlineView.onHovered = onHovered
            self.contentView = underlineView
        }

        // 无论如何都将窗口置于最前面
        self.orderFrontRegardless()
    }

    /// 隐藏窗口
    func hide() {
        self.orderOut(nil)
    }
}

/// 下划线视图 - 绘制红色下划线并处理用户交互
/// 功能：
/// 1. 在底部绘制红色下划线
/// 2. 鼠标悬停时显示轻微高亮背景
/// 3. 鼠标悬停时显示翻译弹窗
/// 4. 响应点击事件以应用翻译
class UnderlineView: NSView {
    /// 下划线对应的文本内容
    var text: String = ""
    /// 点击回调函数
    var onClicked: ((String) -> Void)?
    /// 悬停回调函数（用于显示翻译弹窗）
    var onHovered: ((String) -> Void)?
    /// 是否鼠标悬停中
    private var isHovering = false
    /// 鼠标追踪区域
    private var trackingArea: NSTrackingArea?
    /// 防抖定时器 - 避免鼠标快速移动时频繁触发弹窗
    private var hoverDebounceTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTrackingArea()
    }

    /// 设置鼠标追踪区域（用于检测鼠标进入和离开）
    private func setupTrackingArea() {
        // mouseEnteredAndExited: 追踪鼠标进入和离开事件
        // activeAlways: 即使应用不是活跃状态也追踪
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    /// 更新鼠标追踪区域（当视图大小改变时调用）
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        // 移除旧的追踪区域
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        // 重新设置追踪区域
        setupTrackingArea()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            print("🖱️ [UnderlineView] View added to window, text: \(text), callback set: \(onClicked != nil)")
        }
    }

    /// 绘制视图内容（下划线和鼠标悬停效果）
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 鼠标悬停时绘制轻微高亮背景（参考 Grammarly 的轻微突出效果）
        if isHovering {
            // 使用更柔和的背景色，类似 Grammarly 的悬停效果
            NSColor.systemBlue.withAlphaComponent(0.06).setFill()
            bounds.fill()
        }

        // 在文本区域底部绘制下划线（使用用户配置的颜色）
        let underlineColor = ColorConfig.underlineColor.nsColor
        underlineColor.setStroke()
        let path = NSBezierPath()

        // 下划线位置：距离底部 2 像素
        let underlineY: CGFloat = 2
        path.move(to: NSPoint(x: 0, y: underlineY))           // 起点：左边
        path.line(to: NSPoint(x: bounds.width, y: underlineY)) // 终点：右边
        path.lineWidth = 1                                     // 线宽：1 像素
        path.stroke()                                          // 绘制路径
    }

    /// 鼠标进入视图时触发
    override func mouseEntered(with event: NSEvent) {
        print("🖱️ [UnderlineView] Mouse entered: \(text)")
        isHovering = true                 // 标记为悬停状态
        NSCursor.pointingHand.push()      // 切换为手形指针
        needsDisplay = true               // 触发重绘（显示轻微背景）

        // 使用防抖定时器，避免鼠标快速移动时频繁触发弹窗
        hoverDebounceTimer?.invalidate()
        hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self = self, let callback = self.onHovered else { return }
            print("🖱️ [UnderlineView] Calling onHovered callback after debounce")
            callback(self.text)
        }
    }

    /// 鼠标离开视图时触发
    override func mouseExited(with event: NSEvent) {
        print("🖱️ [UnderlineView] Mouse exited: \(text)")
        isHovering = false                // 取消悬停状态
        NSCursor.pop()                    // 恢复默认指针
        needsDisplay = true               // 触发重绘（移除背景）

        // 取消防抖定时器
        hoverDebounceTimer?.invalidate()
        hoverDebounceTimer = nil
    }

    /// 鼠标点击视图时触发（用于直接应用翻译）
    override func mouseDown(with event: NSEvent) {
        print("🖱️ [UnderlineView] Mouse down on: \(text)")
        // 调用点击回调函数（如果需要的话）
        if let callback = onClicked {
            print("🖱️ [UnderlineView] Calling onClicked callback")
            callback(text)
        }
    }

    /// 允许在不激活窗口的情况下接收第一次鼠标点击
    /// 这样用户可以直接点击下划线，而不需要先激活 Translayr 应用
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    /// 让整个视图区域都能响应鼠标事件
    /// - Parameter point: 鼠标点击的位置
    /// - Returns: 如果点击在视图范围内，返回 self；否则返回 nil
    override func hitTest(_ point: NSPoint) -> NSView? {
        return bounds.contains(point) ? self : nil
    }
}

/// 下划线窗口管理器 - 负责管理所有下划线窗口和翻译弹窗
/// 职责：
/// 1. 管理所有下划线窗口的创建、显示、隐藏
/// 2. 坐标转换（Accessibility API 坐标 → Cocoa 窗口坐标）
/// 3. 处理点击下划线时的翻译请求
/// 4. 显示和管理翻译弹窗
@MainActor
class OverlayWindowManager {
    /// 单例实例
    static let shared = OverlayWindowManager()

    /// 所有下划线窗口的字典（key: "位置-长度"，value: OverlayWindow）
    private var overlayWindows: [String: OverlayWindow] = [:]

    /// 当前显示的翻译弹窗（强引用，防止被过早释放导致 crash）
    private var currentTranslationPopup: NSPanel?

    /// 私有初始化函数（单例模式）
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

    /// 为检测到的文本项显示下划线
    /// - Parameters:
    ///   - item: 检测到的文本项（包含文本内容和位置范围）
    ///   - bounds: 文本的屏幕位置（Accessibility API 坐标系）
    ///   - element: Accessibility 元素引用
    func showUnderline(for item: DetectedTextItem, at bounds: NSRect, element: AXUIElement) {
        // 生成窗口的唯一标识符（基于文本位置和长度）
        let key = "\(item.range.location)-\(item.range.length)"

        // 坐标系转换说明：
        // - Accessibility API: 原点在屏幕左上角，Y 坐标向下增加
        // - macOS Cocoa 窗口: 原点在屏幕左下角，Y 坐标向上增加
        // 因此需要翻转 Y 坐标
        guard let mainScreen = NSScreen.main else {
            print("⚠️ Cannot get main screen")
            return
        }

        let screenHeight = mainScreen.frame.height

        // 坐标转换：从 Accessibility 坐标系转换为 Cocoa 坐标系
        // 公式：cocoaY = 屏幕高度 - axY - 文本高度
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

        // 定义悬停回调函数（弱引用 self 防止循环引用）
        let hoverHandler: (String) -> Void = { [weak self] text in
            print("🖱️ [OverlayWindowManager] Hover handler triggered for: \(text)")
            Task { @MainActor in
                await self?.handleTextHovered(text, item: item, bounds: screenBounds)
            }
        }

        // 定义点击回调函数（弱引用 self 防止循环引用）
        let clickHandler: (String) -> Void = { [weak self] text in
            print("🖱️ [OverlayWindowManager] Click handler triggered for: \(text)")
            // 点击时可以用于其他操作（如果需要的话）
        }

        // 创建或更新下划线窗口
        if let window = overlayWindows[key] {
            // 窗口已存在，直接更新
            window.showUnderline(at: screenBounds, text: item.text, onClicked: clickHandler, onHovered: hoverHandler)
        } else {
            // 创建新窗口
            let window = OverlayWindow(frame: screenBounds)
            window.showUnderline(at: screenBounds, text: item.text, onClicked: clickHandler, onHovered: hoverHandler)
            overlayWindows[key] = window
        }
    }

    /// 隐藏所有下划线窗口
    func hideAll() {
        // 遍历所有窗口并隐藏
        for window in overlayWindows.values {
            window.hide()
        }
        // 清空窗口字典
        overlayWindows.removeAll()
    }

    /// 关闭翻译弹窗
    func closeTranslationPopup() {
        currentTranslationPopup?.close()
        currentTranslationPopup = nil
    }

    /// 处理鼠标悬停在下划线上的事件（显示翻译弹窗）
    /// - Parameters:
    ///   - text: 悬停的文本内容
    ///   - item: 检测到的文本项
    ///   - bounds: 文本的屏幕位置（Cocoa 坐标系）
    private func handleTextHovered(_ text: String, item: DetectedTextItem, bounds: NSRect) async {
        print("🔄 Hover detected, showing popup for: \(text)")

        // 先显示弹窗（loading 状态），不阻塞 UI
        showTranslationPopup(for: text, translations: [], near: bounds) { [weak self] translation in
            // 用户选择翻译后，在外部应用中替换文本
            self?.replaceTextInExternalApp(item: item, with: translation)
        }

        // 异步获取翻译结果
        let translation = await SpellCheckMonitor.shared.translateItem(item)
        let translations = translation.isEmpty ? [] : [translation]

        // 更新弹窗内容（用翻译结果替换 loading）
        if !translations.isEmpty {
            showTranslationPopup(for: text, translations: translations, near: bounds) { [weak self] translation in
                self?.replaceTextInExternalApp(item: item, with: translation)
            }
        }
    }

    /// 处理下划线被点击的事件（可选功能，当前未使用）
    /// - Parameters:
    ///   - text: 被点击的文本内容
    ///   - item: 检测到的文本项
    ///   - bounds: 文本的屏幕位置（Cocoa 坐标系）
    private func handleTextClicked(_ text: String, item: DetectedTextItem, bounds: NSRect) async {
        // 点击时可以执行其他操作（如果需要的话）
        print("🔄 Click detected for: \(text)")
    }

    /// 在外部应用中替换文本
    /// - Parameters:
    ///   - item: 要替换的文本项
    ///   - translation: 翻译后的文本
    private func replaceTextInExternalApp(item: DetectedTextItem, with translation: String) {
        print("🔄 Replacing '\(item.text)' with '\(translation)' in external app")

        // 使用 AccessibilityMonitor 在外部应用中替换文本
        AccessibilityMonitor.shared.replaceText(in: item.range, with: translation)

        // 隐藏所有下划线（因为文本已改变，旧的下划线位置不再有效）
        hideAll()

        // AccessibilityMonitor 的定时器会自动检测到新文本并重新显示下划线
    }

    /// 显示翻译弹窗
    /// - Parameters:
    ///   - text: 原文本
    ///   - translations: 翻译候选列表
    ///   - textBounds: 文本的屏幕位置（Cocoa 坐标系）
    ///   - onSelect: 用户选择翻译时的回调函数
    private func showTranslationPopup(for text: String, translations: [String], near textBounds: NSRect, onSelect: ((String) -> Void)? = nil) {
        // 关闭之前的弹窗（如果有）
        currentTranslationPopup?.close()
        currentTranslationPopup = nil

        // 定义弹窗尺寸（参考 Grammarly 的弹窗大小）
        let popupWidth: CGFloat = 280
        let popupHeight: CGFloat = 200

        // 计算弹窗位置（默认在文字上方，间距 8 像素，类似 Grammarly）
        var popupX = textBounds.origin.x
        var popupY = textBounds.origin.y + textBounds.size.height + 8

        // 如果弹窗会超出屏幕顶部，则显示在文字下方
        if let screen = NSScreen.main {
            if popupY + popupHeight > screen.frame.maxY - 20 {
                popupY = textBounds.origin.y - popupHeight - 8
            }
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

        // 创建 NSPanel（更适合临时弹窗，失去焦点时会自动隐藏）
        let popupPanel = NSPanel(
            contentRect: popupFrame,
            styleMask: [.borderless, .nonactivatingPanel],  // 无边框、不激活窗口
            backing: .buffered,
            defer: false
        )

        // 窗口配置
        popupPanel.level = .popUpMenu              // 使用弹出菜单级别，确保在下划线之上
        popupPanel.isMovableByWindowBackground = false  // 不可通过背景拖动
        popupPanel.hidesOnDeactivate = true        // 失去焦点时自动隐藏
        popupPanel.isOpaque = false                // 透明窗口
        popupPanel.backgroundColor = .clear        // 无背景色
        popupPanel.hasShadow = false               // 不使用系统阴影（使用 SwiftUI 阴影）

        // 创建 SwiftUI 视图内容
        let translationsView = TranslationPopupView(
            originalText: text,
            translations: translations,
            onSelect: { [weak self] translation in
                print("✅ Selected translation: \(translation)")

                // 调用外部回调函数（如果有）
                onSelect?(translation)

                // 关闭弹窗
                self?.currentTranslationPopup?.close()
                self?.currentTranslationPopup = nil
            }
        )

        // 将 SwiftUI 视图设置为窗口内容
        popupPanel.contentView = NSHostingView(rootView: translationsView)

        // 强引用持有窗口，防止被过早释放导致 crash
        currentTranslationPopup = popupPanel

        // 显示窗口
        popupPanel.makeKeyAndOrderFront(nil)

        print("🪟 [OverlayWindowManager] Showing popup at \(popupFrame)")
    }
}

// MARK: - Translation Popup View

struct TranslationPopupView: View {
    let originalText: String
    let translations: [String]
    let onSelect: (String) -> Void

    @State private var hoveredIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with gradient
            HStack(spacing: 6) {
                Image(systemName: "character.book.closed.fill")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text("Translation")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(originalText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                }

                Spacer()

                // 关闭按钮
                Button(action: {
                    OverlayWindowManager.shared.closeTranslationPopup()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [
                        Color(NSColor.controlBackgroundColor),
                        Color(NSColor.controlBackgroundColor).opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Divider()

            // Translations list
            if translations.isEmpty {
                VStack(spacing: 8) {
                    Spacer()

                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(.circular)

                    Text("Translating...")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 3) {
                        ForEach(Array(translations.enumerated()), id: \.offset) { index, translation in
                            TranslationRow(
                                translation: translation,
                                isHovered: hoveredIndex == index,
                                onSelect: { onSelect(translation) },
                                onHover: { hovering in
                                    hoveredIndex = hovering ? index : nil
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                }
            }
        }
        .frame(width: 280, height: 200)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Translation Row Component

struct TranslationRow: View {
    let translation: String
    let isHovered: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                // Translation text
                Text(translation)
                    .font(.system(size: 13, weight: isHovered ? .medium : .regular))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(5)

                // Arrow icon with animation
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isHovered ? [.blue, .purple] : [.gray, .gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.blue.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isHovered ? Color.blue.opacity(0.3) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            onHover(hovering)
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

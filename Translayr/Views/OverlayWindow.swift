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

        // 窗口层级：略高于普通窗口（而不是浮动在所有窗口之上）
        // 这样下划线只会显示在目标应用上方，而不会覆盖其他应用
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.normalWindow)) + 1)

        // 窗口行为：在所有空间显示，并可在全屏应用上方显示
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 窗口不可通过背景拖动（不会在窗口切换器中显示）
        self.isMovableByWindowBackground = false

        // 忽略鼠标点击事件，让点击穿透到底层应用（类似Grammarly）
        // 这样用户可以点击文字插入光标
        self.ignoresMouseEvents = true

        // 鼠标移动检测通过全局监听器实现，见UnderlineView
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
/// 4. 点击事件穿透，不影响底层文字编辑
class UnderlineView: NSView {
    /// 下划线对应的文本内容
    var text: String = ""
    /// 点击回调函数（目前不使用，因为点击会穿透）
    var onClicked: ((String) -> Void)?
    /// 悬停回调函数（用于显示翻译弹窗）
    var onHovered: ((String) -> Void)?
    /// 是否鼠标悬停中
    private var isHovering = false
    /// 防抖定时器 - 避免鼠标快速移动时频繁触发弹窗
    private var hoverDebounceTimer: Timer?
    /// 全局鼠标监听器
    private var globalMouseMonitor: Any?
    /// 鼠标位置检查定时器
    private var mouseCheckTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 设置鼠标位置监控
    private func setupMouseMonitoring() {
        // 使用定时器定期检查鼠标位置（因为窗口ignoresMouseEvents = true）
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMousePosition()
        }
        RunLoop.main.add(timer, forMode: .common)
        mouseCheckTimer = timer
    }

    /// 停止鼠标监控
    private func stopMouseMonitoring() {
        mouseCheckTimer?.invalidate()
        mouseCheckTimer = nil
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
    }

    /// 检查鼠标是否在视图范围内
    private func checkMousePosition() {
        guard let window = window else { return }

        // 获取鼠标在屏幕上的位置
        let mouseLocation = NSEvent.mouseLocation

        // 转换为窗口坐标
        let screenRect = NSRect(origin: mouseLocation, size: .zero)
        let windowRect = window.convertFromScreen(screenRect)
        let windowLocation = windowRect.origin

        // 转换为视图坐标
        let viewLocation = convert(windowLocation, from: nil)

        // 检查鼠标是否在视图范围内
        let wasHovering = isHovering
        isHovering = bounds.contains(viewLocation)

        // 状态改变时触发回调
        if isHovering && !wasHovering {
            handleMouseEntered()
        } else if !isHovering && wasHovering {
            handleMouseExited()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            print("🖱️ [UnderlineView] View added to window, text: \(text)")
            setupMouseMonitoring()
        } else {
            stopMouseMonitoring()
        }
    }

    deinit {
        stopMouseMonitoring()
        hoverDebounceTimer?.invalidate()
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

    /// 处理鼠标进入视图
    private func handleMouseEntered() {
        print("🖱️ [UnderlineView] Mouse entered: \(text)")
        needsDisplay = true               // 触发重绘（显示轻微背景）

        // 使用防抖定时器，避免鼠标快速移动时频繁触发弹窗
        hoverDebounceTimer?.invalidate()
        hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self = self, let callback = self.onHovered else { return }

            Task { @MainActor in
                // 如果已经有弹窗在显示，不触发新的弹窗
                if OverlayWindowManager.shared.hasActivePopup() {
                    print("🖱️ [UnderlineView] Popup already active, skipping hover callback")
                    return
                }

                print("🖱️ [UnderlineView] Calling onHovered callback after debounce")
                callback(self.text)
            }
        }
    }

    /// 处理鼠标离开视图
    private func handleMouseExited() {
        print("🖱️ [UnderlineView] Mouse exited: \(text)")
        needsDisplay = true               // 触发重绘（移除背景）

        // 取消防抖定时器
        hoverDebounceTimer?.invalidate()
        hoverDebounceTimer = nil

        // 延迟关闭弹窗，给用户时间移动鼠标到弹窗上
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            // 如果鼠标不在弹窗内，则关闭弹窗
            if !OverlayWindowManager.shared.isMouseInPopup() {
                OverlayWindowManager.shared.closeTranslationPopup()
            }
        }
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

        // 定义点击回调函数
        let clickHandler: (String) -> Void = { text in
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

    /// 检查是否有弹窗正在显示
    func hasActivePopup() -> Bool {
        return currentTranslationPopup != nil
    }

    /// 检查鼠标是否在弹窗内
    func isMouseInPopup() -> Bool {
        guard let popup = currentTranslationPopup else { return false }

        let mouseLocation = NSEvent.mouseLocation
        let windowFrame = popup.frame

        return windowFrame.contains(mouseLocation)
    }

    /// 处理鼠标悬停在下划线上的事件（显示翻译弹窗）
    /// - Parameters:
    ///   - text: 悬停的文本内容
    ///   - item: 检测到的文本项
    ///   - bounds: 文本的屏幕位置（Cocoa 坐标系）
    private func handleTextHovered(_ text: String, item: DetectedTextItem, bounds: NSRect) async {
        print("🔄 Hover detected, showing popup for: \(text)")

        // 先显示弹窗（loading 状态），不阻塞 UI
        showTranslationPopup(for: text, translation: "", near: bounds) { [weak self] translation in
            // 用户选择翻译后，在外部应用中替换文本
            self?.replaceTextInExternalApp(item: item, with: translation)
        }

        // 异步获取翻译结果
        let translation = await SpellCheckMonitor.shared.translateItem(item)

        // 更新弹窗内容（用翻译结果替换 loading）
        if !translation.isEmpty {
            showTranslationPopup(for: text, translation: translation, near: bounds) { [weak self] translation in
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
    private func showTranslationPopup(for text: String, translation: String, near textBounds: NSRect, onSelect: ((String) -> Void)? = nil) {
        // 关闭之前的弹窗（如果有）
        currentTranslationPopup?.close()
        currentTranslationPopup = nil

        // 定义弹窗固定尺寸 - 宽度更宽，高度固定
        let popupWidth: CGFloat = 400
        let popupHeight: CGFloat = 100  // 固定高度，足够容纳头部 + 2行文字

        // 计算弹窗位置（默认在文字上方，间距 8 像素）
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
        // 弹窗层级：比下划线窗口高（下划线是 normalWindow + 1，弹窗是 normalWindow + 2）
        popupPanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.normalWindow)) + 2)
        popupPanel.isMovableByWindowBackground = false  // 不可通过背景拖动
        popupPanel.hidesOnDeactivate = false       // 不自动隐藏（手动控制）
        popupPanel.isOpaque = false                // 透明窗口
        popupPanel.backgroundColor = .clear        // 无背景色
        popupPanel.hasShadow = false               // 不使用系统阴影（使用 SwiftUI 阴影）
        popupPanel.ignoresMouseEvents = false      // 弹窗需要接收鼠标事件

        // 创建 SwiftUI 视图内容
        let translationsView = TranslationPopupView(
            originalText: text,
            translation: translation,
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
    let translation: String
    let onSelect: (String) -> Void

    @State private var isMouseInside = false
    @State private var isCloseButtonHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Translayr 品牌头部
            HStack(spacing: 6) {
                // Logo 图标
                Image(systemName: "character.textbox.badge.sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue.opacity(0.8))

                Text("Translayr")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                // 关闭按钮
                Button(action: {
                    OverlayWindowManager.shared.closeTranslationPopup()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isCloseButtonHovered ? .primary : .secondary)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(isCloseButtonHovered ? Color.primary.opacity(0.06) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isCloseButtonHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
            .frame(height: 37)  // 固定头部高度

            Divider()

            // 翻译结果区域 - 固定高度
            Group {
                if translation.isEmpty {
                    // Loading 状态
                    HStack(spacing: 8) {
                        Text("Translating...")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 62)  // 固定高度，与内容区域一致
                } else {
                    // 翻译文字 - 紧凑显示，最多2行
                    TranslationContentRow(
                        translation: translation,
                        onSelect: { onSelect(translation) }
                    )
                    .frame(height: 62)  // 固定高度
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 400, height: 100)  // 强制固定整体尺寸
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.primary.opacity(0.15), radius: 16, x: 0, y: 4)
        .shadow(color: Color.primary.opacity(0.08), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Translation Content Row Component

struct TranslationContentRow: View {
    let translation: String
    let onSelect: () -> Void

    @State var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 10) {
                // 翻译文本 - 紧凑显示，最多2行
                Text(translation)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .truncationMode(.tail)

                // 箭头图标 - 悬停时显示
                if isHovered {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)  // 填充整个可用高度
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.blue.opacity(0.08) : Color(nsColor: .windowBackgroundColor))
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

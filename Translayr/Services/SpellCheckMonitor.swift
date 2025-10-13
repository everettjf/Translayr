//
//  SpellCheckMonitor.swift
//  Translayr
//
//  拼写检查监控器 - 协调 AccessibilityMonitor 和 OverlayWindow 的工作
//

import SwiftUI
import Combine

/// 拼写检查监控器 - 核心协调类
/// 负责：
/// 1. 监听 AccessibilityMonitor 获取的文本
/// 2. 检测配置语言的文本（句子和词组）
/// 3. 显示和更新 overlay 下划线
/// 4. 处理翻译请求
@MainActor
class SpellCheckMonitor: ObservableObject {
    static let shared = SpellCheckMonitor()

    /// 检测到的文本项列表
    @Published var detectedItems: [DetectedTextItem] = []

    // MARK: - Dependencies（依赖）

    /// 辅助功能监控器 - 获取其他应用的文本
    private let accessibilityMonitor = AccessibilityMonitor.shared

    /// 拼写服务 - 提供翻译功能
    private let spellService = SpellService()

    /// Overlay 窗口管理器 - 管理下划线显示
    private let overlayManager = OverlayWindowManager.shared

    /// Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // 监听文本变化 - 检测配置语言的文本
        accessibilityMonitor.$currentText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)  // 防抖，避免频繁更新
            .sink { [weak self] text in
                self?.detectText(text)
            }
            .store(in: &cancellables)

        // 监听窗口位置变化 - 优化拖动体验
        accessibilityMonitor.$windowPositionChanged
            .dropFirst()  // 跳过初始值
            .sink { [weak self] _ in
                // 窗口开始移动时，立即隐藏下划线（提升拖动流畅度）
                self?.overlayManager.hideAll()
                print("🪟 [SpellCheckMonitor] Window moving, hiding overlays")
            }
            .store(in: &cancellables)

        // 监听窗口位置变化 - 等待稳定后再显示下划线
        accessibilityMonitor.$windowPositionChanged
            .dropFirst()  // 跳过初始值
            .debounce(for: .seconds(2), scheduler: RunLoop.main)  // 2秒防抖，等待窗口稳定
            .sink { [weak self] _ in
                // 窗口停止移动 2 秒后，重新显示下划线
                print("🪟 [SpellCheckMonitor] Window stable, showing overlays")
                self?.updateOverlayPositions()
            }
            .store(in: &cancellables)

        // 监听屏幕/空间切换 - 使用多个通知提高灵敏度

        // 通知 1: 活动空间改变（Mission Control 切换桌面）
        NotificationCenter.default.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.overlayManager.hideAll()
                print("🖥️ [SpellCheckMonitor] Active space changed, hiding all overlays")
            }
            .store(in: &cancellables)

        // 通知 2: 屏幕参数改变（分辨率、显示器配置变化）
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.overlayManager.hideAll()
                print("🖥️ [SpellCheckMonitor] Screen parameters changed, hiding all overlays")
            }
            .store(in: &cancellables)

        // 通知 3: 工作区切换开始（Mission Control 动画开始时就隐藏）
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.overlayManager.hideAll()
                print("🖥️ [SpellCheckMonitor] Workspace space changed, hiding all overlays")
            }
            .store(in: &cancellables)

        // 监听文本框滚动 - 立即隐藏下划线
        accessibilityMonitor.$textScrolled
            .dropFirst()  // 跳过初始值
            .sink { [weak self] _ in
                // 文本框滚动时，立即隐藏下划线
                self?.overlayManager.hideAll()
                print("📜 [SpellCheckMonitor] Text scrolled, hiding overlays")
            }
            .store(in: &cancellables)

        // 监听文本框滚动 - 等待稳定后再显示下划线
        accessibilityMonitor.$textScrolled
            .dropFirst()  // 跳过初始值
            .debounce(for: .seconds(1), scheduler: RunLoop.main)  // 1秒防抖，等待滚动停止
            .sink { [weak self] _ in
                // 滚动停止 1 秒后，重新显示下划线
                print("📜 [SpellCheckMonitor] Scroll stable, showing overlays")
                self?.updateOverlayPositions()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods（公共方法）

    /// 开始监控系统范围的文本输入
    func startMonitoring() {
        print("\n🚀 [SpellCheckMonitor] Starting spell check monitoring")
        accessibilityMonitor.startMonitoring()
        print("✅ [SpellCheckMonitor] AccessibilityMonitor started")
    }

    /// 停止监控
    func stopMonitoring() {
        print("⏹ [SpellCheckMonitor] Stopping spell check monitoring")
        accessibilityMonitor.stopMonitoring()
    }

    /// 翻译指定的检测项（当用户点击下划线时调用）
    /// - Parameter item: 要翻译的文本项
    /// - Returns: 翻译结果字符串（失败时为空字符串）
    func translateItem(_ item: DetectedTextItem) async -> String {
        print("🔄 Translating: \(item.text)")

        // 直接翻译整个文本，不分词
        do {
            let translation = try await spellService.translateText(item.text)
            print("✅ Got translation: \(translation)")

            return translation
        } catch {
            print("❌ Translation failed: \(error)")
            return ""
        }
    }

    // MARK: - Private Methods（私有方法）

    /// 检测文本中的目标语言内容
    /// 策略：
    /// 1. 优先检测语言句子（以句号、问号、叹号分隔，保留引号括号，支持中英文混合）
    /// 2. 然后检测独立的语言词组（根据语言配置的最小长度）
    /// - Parameter text: 要检测的文本
    private func detectText(_ text: String) {
        guard !text.isEmpty else {
            if !detectedItems.isEmpty {
                print("🔍 [SpellCheckMonitor] Text empty, clearing items")
                detectedItems = []
                overlayManager.hideAll()
            }
            return
        }

        let language = LanguageConfig.sourceLanguage
        print("\n🔍 [SpellCheckMonitor] Detecting \(language.displayName) in text (\(text.count) chars)")
        print("   First 100 chars: \(String(text.prefix(100)))")

        var items: [DetectedTextItem] = []

        // Priority 1: Detect sentences using improved logic
        // 按句号、破折号、问号、叹号分割，保留引号括号，支持中英文混合
        let sentences = detectSentences(in: text, language: language)
        print("   Found \(sentences.count) sentence(s)")

        for sentence in sentences {
            print("   Sentence: \(sentence.text)")
            items.append(sentence)
        }

        // Priority 2: Detect individual words (based on language min length) not in sentences
        let coveredRanges = items.map { $0.range }
        let wordPattern = "[\(language.unicodePattern)]{\(language.minWordLength),}"
        if let wordRegex = try? NSRegularExpression(pattern: wordPattern, options: []) {
            let matches = wordRegex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            print("   Found \(matches.count) word matches (before filtering)")

            var wordCount = 0
            for match in matches {
                let covered = coveredRanges.contains { NSIntersectionRange($0, match.range).length > 0 }
                if !covered, let range = Range(match.range, in: text) {
                    let word = String(text[range])
                    print("   Word: \(word)")
                    items.append(DetectedTextItem(
                        text: word,
                        range: match.range,
                        type: .word
                    ))
                    wordCount += 1
                }
            }
            print("   Added \(wordCount) unique words")
        }

        detectedItems = items
        print("📋 [SpellCheckMonitor] Total detected items: \(items.count)")

        // Show overlay windows for detected items (only for external apps)
        showOverlayWindows(for: items)
    }

    /// 检测句子的智能算法
    /// 规则：
    /// - 句子以句号（。.）、逗号（，,）、问号（？?）、叹号（！!）、分号（；;）、破折号（—-）、换行符（\n）结束
    /// - 引号和括号内的内容保持在一起（不被分割）
    /// - 支持中英文混合（不因为有英文就分割）
    /// - Parameter text: 要检测的文本
    /// - Parameter language: 目标语言
    /// - Returns: 检测到的句子列表
    private func detectSentences(in text: String, language: Language) -> [DetectedTextItem] {
        var sentences: [DetectedTextItem] = []
        let nsText = text as NSString
        let textLength = nsText.length

        // 句子结束符：句号、逗号、问号、叹号、分号、破折号、换行符
        let sentenceEnders: Set<unichar> = [
            unichar("。".utf16.first!),  // 中文句号
            unichar(".".utf16.first!),   // 英文句号
            unichar("，".utf16.first!),  // 中文逗号
            unichar(",".utf16.first!),   // 英文逗号
            unichar("？".utf16.first!),  // 中文问号
            unichar("?".utf16.first!),   // 英文问号
            unichar("！".utf16.first!),  // 中文叹号
            unichar("!".utf16.first!),   // 英文叹号
            unichar("；".utf16.first!),  // 中文分号
            unichar(";".utf16.first!),   // 英文分号
            unichar("—".utf16.first!),   // 中文破折号
            unichar("-".utf16.first!),   // 英文破折号
            unichar("\n".utf16.first!),  // 换行符
            unichar("\r".utf16.first!)   // 回车符（Windows风格）
        ]

        // 创建语言字符检测的正则表达式
        guard let languageRegex = try? NSRegularExpression(pattern: "[\(language.unicodePattern)]", options: []) else {
            return []
        }

        var currentStart: Int? = nil
        var parenDepth = 0  // 括号深度
        var quoteDepth = 0  // 引号深度

        // 使用NSString遍历，避免String的O(n)索引开销
        for i in 0..<textLength {
            let char = nsText.character(at: i)

            // 检查是否是目标语言字符
            let charRange = NSRange(location: i, length: 1)
            let hasLanguageChar = languageRegex.firstMatch(in: text, options: [], range: charRange) != nil

            // 如果遇到目标语言字符，标记句子开始
            if hasLanguageChar && currentStart == nil {
                currentStart = i
            }

            // 更新括号和引号深度
            let openParens: Set<unichar> = [
                unichar("(".utf16.first!),
                unichar("（".utf16.first!),
                unichar("[".utf16.first!),
                unichar("【".utf16.first!)
            ]
            let closeParens: Set<unichar> = [
                unichar(")".utf16.first!),
                unichar("）".utf16.first!),
                unichar("]".utf16.first!),
                unichar("】".utf16.first!)
            ]
            let quotes: Set<unichar> = [
                unichar("\"".utf16.first!),
                0x201C, // "
                0x201D, // "
                unichar("'".utf16.first!),
                0x2018, // '
                0x2019  // '
            ]

            if openParens.contains(char) {
                parenDepth += 1
            } else if closeParens.contains(char) {
                parenDepth = max(0, parenDepth - 1)
            } else if quotes.contains(char) {
                quoteDepth = (quoteDepth + 1) % 2
            }

            // 检查是否是句子结束符
            if let start = currentStart,
               sentenceEnders.contains(char),
               parenDepth == 0,
               quoteDepth == 0 {
                // 找到句子结束 - 但不包括结束符本身（i 是结束符的位置）
                let sentenceRange = NSRange(location: start, length: i - start)
                let sentenceText = nsText.substring(with: sentenceRange)
                    .trimmingCharacters(in: .whitespaces)

                // 只保留包含目标语言字符的句子
                if !sentenceText.isEmpty {
                    // 调整范围以匹配修剪后的文本
                    let trimmedRange = nsText.range(of: sentenceText, options: [], range: sentenceRange)

                    sentences.append(DetectedTextItem(
                        text: sentenceText,
                        range: trimmedRange,
                        type: .sentence
                    ))
                }

                currentStart = nil
            }
        }

        // 处理未结束的句子（到文本末尾）
        if let start = currentStart {
            let sentenceRange = NSRange(location: start, length: textLength - start)
            let sentenceText = nsText.substring(with: sentenceRange)
                .trimmingCharacters(in: .whitespaces)

            if !sentenceText.isEmpty {
                let trimmedRange = nsText.range(of: sentenceText, options: [], range: sentenceRange)

                sentences.append(DetectedTextItem(
                    text: sentenceText,
                    range: trimmedRange,
                    type: .sentence
                ))
            }
        }

        return sentences
    }

    /// Show overlay windows for detected text in external apps
    private func showOverlayWindows(for items: [DetectedTextItem]) {
        // Only show overlays if monitoring external apps
        // (Don't show overlays for our own app's text editor)
        guard let currentElement = accessibilityMonitor.currentElement else {
            overlayManager.hideAll()
            return
        }

        print("\n🪟 [SpellCheckMonitor] Showing overlay windows for \(items.count) items")

        // Hide previous overlays
        overlayManager.hideAll()

        // Show overlay for each detected item
        for item in items {
            if let bounds = accessibilityMonitor.getBoundsForRange(item.range) {
                print("   Showing overlay for '\(item.text)' at \(bounds)")
                overlayManager.showUnderline(for: item, at: bounds, element: currentElement)
            } else {
                print("   ⚠️ Could not get bounds for '\(item.text)'")
            }
        }
    }

    /// 更新 overlay 位置（当窗口移动或调整大小时）
    /// 重新获取所有检测项的屏幕位置并更新 overlay
    private func updateOverlayPositions() {
        // 只在有检测项且有当前元素时更新
        guard !detectedItems.isEmpty,
              let currentElement = accessibilityMonitor.currentElement else {
            return
        }

        print("\n📍 [SpellCheckMonitor] Updating overlay positions for \(detectedItems.count) items")

        // 为每个 overlay 更新位置
        for item in detectedItems {
            if let bounds = accessibilityMonitor.getBoundsForRange(item.range) {
                overlayManager.showUnderline(for: item, at: bounds, element: currentElement)
            }
        }
    }
}

// MARK: - Supporting Models（支持模型）

/// 检测到的文本项模型 - 表示需要翻译的中文文本
struct DetectedTextItem: Identifiable {
    let id = UUID()
    /// 检测到的文本内容
    let text: String
    /// 文本在原文中的范围
    let range: NSRange
    /// 检测类型（句子或词组）
    let type: DetectionType

    /// 检测类型枚举
    enum DetectionType {
        case sentence  // 句子（包含标点符号）
        case word      // 词组（2个字以上）
    }
}

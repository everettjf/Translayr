//
//  SpellCheckMonitor.swift
//  Spello
//
//  拼写检查监控器 - 协调 AccessibilityMonitor 和 OverlayWindow 的工作
//

import SwiftUI
import Combine

/// 拼写检查监控器 - 核心协调类
/// 负责：
/// 1. 监听 AccessibilityMonitor 获取的文本
/// 2. 检测中文文本（句子和词组）
/// 3. 显示和更新 overlay 下划线
/// 4. 处理翻译请求
@MainActor
class SpellCheckMonitor: ObservableObject {
    static let shared = SpellCheckMonitor()

    /// 检测到的中文文本项列表
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
        // 监听文本变化 - 检测中文文本
        accessibilityMonitor.$currentText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)  // 防抖，避免频繁更新
            .sink { [weak self] text in
                self?.detectChineseText(text)
            }
            .store(in: &cancellables)

        // 监听窗口位置变化 - 更新 overlay 位置
        accessibilityMonitor.$windowPositionChanged
            .dropFirst()  // 跳过初始值
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)  // 短防抖，快速响应位置变化
            .sink { [weak self] _ in
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

    /// 检测文本中的中文内容
    /// 策略：
    /// 1. 优先检测中文句子（以标点符号分隔）
    /// 2. 然后检测独立的中文词组（2个字以上）
    /// - Parameter text: 要检测的文本
    private func detectChineseText(_ text: String) {
        guard !text.isEmpty else {
            if !detectedItems.isEmpty {
                print("🔍 [SpellCheckMonitor] Text empty, clearing items")
                detectedItems = []
                overlayManager.hideAll()
            }
            return
        }

        print("\n🔍 [SpellCheckMonitor] Detecting Chinese in text (\(text.count) chars)")
        print("   First 100 chars: \(String(text.prefix(100)))")

        var items: [DetectedTextItem] = []

        // Priority 1: Detect sentences (split by specific punctuation, excluding parentheses)
        // 仅使用空格、逗号、句号等作为分隔符，不包括括号
        let sentencePattern = "[\\p{Han}][^。！？；，、.!?,;\\s\\n]*[。！？；，、.!?,;\\s]"
        if let sentenceRegex = try? NSRegularExpression(pattern: sentencePattern, options: []) {
            let matches = sentenceRegex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            print("   Found \(matches.count) sentence matches")

            for match in matches {
                if let range = Range(match.range, in: text) {
                    let sentence = String(text[range])
                    print("   Sentence: \(sentence)")
                    items.append(DetectedTextItem(
                        text: sentence,
                        range: match.range,
                        type: .sentence
                    ))
                }
            }
        }

        // Priority 2: Detect individual Chinese words (2+ characters) not in sentences
        let coveredRanges = items.map { $0.range }
        let wordPattern = "[\\p{Han}]{2,}"
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

    /// Show overlay windows for detected Chinese text in external apps
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

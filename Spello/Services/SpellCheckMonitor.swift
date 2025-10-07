//
//  SpellCheckMonitor.swift
//  Spello
//
//  实时拼写检查监控器
//

import SwiftUI
import Combine

@MainActor
class SpellCheckMonitor: ObservableObject {
    static let shared = SpellCheckMonitor()

    @Published var currentSuggestion: Suggestion?
    @Published var isShowingSuggestion = false

    private let accessibilityMonitor = AccessibilityMonitor.shared
    private let spellService = SpellService()
    private var cancellables = Set<AnyCancellable>()
    private var suggestionWindow: FloatingSuggestionWindow?

    private init() {
        // 监听文本变化
        accessibilityMonitor.$currentText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.checkText(text)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func startMonitoring() {
        print("🚀 Starting spell check monitoring")
        accessibilityMonitor.startMonitoring()
    }

    func stopMonitoring() {
        print("⏹ Stopping spell check monitoring")
        accessibilityMonitor.stopMonitoring()
        hideSuggestions()
    }

    func applySuggestion(_ candidate: String) {
        guard let suggestion = currentSuggestion else { return }

        // 替换文本
        accessibilityMonitor.replaceText(in: suggestion.range, with: candidate)

        // 隐藏建议
        hideSuggestions()
    }

    func ignoreSuggestion() {
        guard let suggestion = currentSuggestion else { return }
        spellService.ignore(word: suggestion.word)
        hideSuggestions()
    }

    func hideSuggestions() {
        isShowingSuggestion = false
        currentSuggestion = nil
        suggestionWindow?.orderOut(nil)
    }

    // MARK: - Private Methods

    private func checkText(_ text: String) {
        guard !text.isEmpty else {
            hideSuggestions()
            return
        }

        print("🔍 Checking text: \(text)")

        Task {
            // 获取系统拼写检查建议
            let systemSuggestions = await Task.detached {
                self.spellService.scanSystem(text: text, language: nil)
            }.value

            // 获取 AI 翻译建议
            let aiSuggestions = await spellService.analyzeWithLocalModelAsync(text: text, language: nil)

            // 合并建议
            let allSuggestions = spellService.merge(systemSuggestions, aiSuggestions)

            // 显示第一个建议
            if let firstSuggestion = allSuggestions.first {
                showSuggestion(firstSuggestion)
            } else {
                hideSuggestions()
            }
        }
    }

    private func showSuggestion(_ suggestion: Suggestion) {
        currentSuggestion = suggestion
        isShowingSuggestion = true

        // 创建或更新浮动窗口
        if suggestionWindow == nil {
            suggestionWindow = FloatingSuggestionWindow()
            suggestionWindow?.contentView = NSHostingView(
                rootView: SuggestionWindowContent()
                    .environmentObject(self)
            )
        }

        // 定位窗口在鼠标附近
        positionWindow()

        // 显示窗口
        suggestionWindow?.makeKeyAndOrderFront(nil)

        print("💡 Showing suggestion: \(suggestion.word) -> \(suggestion.candidates.joined(separator: ", "))")
    }

    private func positionWindow() {
        guard let window = suggestionWindow else { return }

        // 获取鼠标位置
        let mouseLocation = NSEvent.mouseLocation

        // 计算窗口位置（在鼠标右下方）
        let windowSize = window.frame.size
        var windowOrigin = CGPoint(
            x: mouseLocation.x + 10,
            y: mouseLocation.y - windowSize.height - 10
        )

        // 确保窗口在屏幕内
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame

            // 检查右边界
            if windowOrigin.x + windowSize.width > screenFrame.maxX {
                windowOrigin.x = mouseLocation.x - windowSize.width - 10
            }

            // 检查上边界
            if windowOrigin.y < screenFrame.minY {
                windowOrigin.y = mouseLocation.y + 10
            }
        }

        window.setFrameOrigin(windowOrigin)
    }
}

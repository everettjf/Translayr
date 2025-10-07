//
//  SpellCheckMonitor.swift
//  Spello
//
//  Minimal spell check monitor using NSSpellChecker.substitutionPanel
//

import SwiftUI
import Combine

@MainActor
class SpellCheckMonitor: ObservableObject {
    static let shared = SpellCheckMonitor()

    @Published var detectedItems: [DetectedTextItem] = []

    private let accessibilityMonitor = AccessibilityMonitor.shared
    private let spellService = SpellService()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Monitor text changes - only detect Chinese text
        accessibilityMonitor.$currentText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.detectChineseText(text)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func startMonitoring() {
        print("\n🚀 [SpellCheckMonitor] Starting spell check monitoring")
        accessibilityMonitor.startMonitoring()
        print("✅ [SpellCheckMonitor] AccessibilityMonitor started")
    }

    func stopMonitoring() {
        print("⏹ [SpellCheckMonitor] Stopping spell check monitoring")
        accessibilityMonitor.stopMonitoring()
    }

    /// Translate a specific detected item when clicked
    func translateItem(_ item: DetectedTextItem) async -> [String] {
        print("🔄 Translating: \(item.text)")

        // Get AI translation suggestions
        let aiSuggestions = await spellService.analyzeWithLocalModelAsync(text: item.text, language: nil)

        // Extract translation candidates
        let translations = aiSuggestions.flatMap { $0.candidates }
        print("✅ Got \(translations.count) translations")

        return translations
    }

    // MARK: - Private Methods

    /// Detect Chinese text (sentences first, then words)
    private func detectChineseText(_ text: String) {
        guard !text.isEmpty else {
            if !detectedItems.isEmpty {
                print("🔍 [SpellCheckMonitor] Text empty, clearing items")
                detectedItems = []
            }
            return
        }

        print("\n🔍 [SpellCheckMonitor] Detecting Chinese in text (\(text.count) chars)")
        print("   First 100 chars: \(String(text.prefix(100)))")

        var items: [DetectedTextItem] = []

        // Priority 1: Detect sentences (split by any punctuation)
        let sentencePattern = "[\\p{Han}][^。！？；，、.!?,;（）()【】\\[\\]「」『』{}\\n]*[。！？；，、.!?,;（）()【】\\[\\]「」『』{}]"
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
    }
}

// MARK: - Supporting Models

/// Model for detected text items that need translation
struct DetectedTextItem: Identifiable {
    let id = UUID()
    let text: String
    let range: NSRange
    let type: DetectionType

    enum DetectionType {
        case sentence
        case word
    }
}

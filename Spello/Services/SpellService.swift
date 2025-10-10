//
//  SpellService.swift
//  Spello
//
//  Created by XNU on 9/28/25.
//

import Foundation
import AppKit
import Combine

class SpellService: ObservableObject, SpellAnalyzing {
    @Published var isLocalModelEnabled: Bool = true  // 默认启用 AI 翻译
    private let spellChecker = NSSpellChecker.shared
    private var ignoredWords: Set<String> = []

    init() {
        spellChecker.automaticallyIdentifiesLanguages = true
    }

    func scanSystem(text: String, language: String? = nil) -> [Suggestion] {
        var suggestions: [Suggestion] = []
        let nsText = text as NSString
        var currentRange = NSRange(location: 0, length: nsText.length)

        while currentRange.location < nsText.length {
            let spellRange = spellChecker.checkSpelling(
                of: text,
                startingAt: currentRange.location,
                language: language,
                wrap: false,
                inSpellDocumentWithTag: 0,
                wordCount: nil
            )

            if spellRange.location == NSNotFound {
                break
            }

            let misspelledWord = nsText.substring(with: spellRange)

            if !ignoredWords.contains(misspelledWord) {
                let candidates = spellChecker.guesses(
                    forWordRange: spellRange,
                    in: text,
                    language: language,
                    inSpellDocumentWithTag: 0
                ) ?? []

                let contextRange = getContextRange(for: spellRange, in: nsText)
                let context = nsText.substring(with: contextRange)

                let suggestion = Suggestion(
                    word: misspelledWord,
                    range: spellRange,
                    context: context,
                    candidates: candidates,
                    source: "System"
                )

                suggestions.append(suggestion)
            }

            currentRange.location = spellRange.location + spellRange.length
            currentRange.length = nsText.length - currentRange.location
        }

        return suggestions
    }

    func analyzeWithLocalModel(text: String, language: String? = nil) -> [Suggestion] {
        guard isLocalModelEnabled else { return [] }

        // For synchronous operation, return empty array
        // Real analysis happens in async version
        return []
    }

    // Async version using Ollama for translation
    func analyzeWithLocalModelAsync(text: String, language: String? = nil) async -> [Suggestion] {
        guard isLocalModelEnabled else { return [] }

        let localModelClient = LocalModelClient()

        do {
            let modelSuggestions = try await localModelClient.analyzeText(text, language: language)
            let nsText = text as NSString

            return modelSuggestions.map { modelSuggestion in
                let contextRange = getContextRange(for: modelSuggestion.range, in: nsText)
                let context = nsText.substring(with: contextRange)

                return modelSuggestion.toSuggestion(context: context)
            }
        } catch {
            print("Local model error: \(error)")
            // 失败时返回空数组，不影响系统拼写检查
            return []
        }
    }

    // 直接翻译文本，不分词
    func translateText(_ text: String) async throws -> String {
        guard isLocalModelEnabled else {
            throw LocalModelError.serverError
        }

        let localModelClient = LocalModelClient()
        return try await localModelClient.translateText(text)
    }

    func merge(_ systemSuggestions: [Suggestion], _ modelSuggestions: [Suggestion]) -> [Suggestion] {
        var mergedSuggestions: [Suggestion] = []
        var processedRanges: Set<NSRange> = []

        // Add system suggestions first
        for suggestion in systemSuggestions {
            mergedSuggestions.append(suggestion)
            processedRanges.insert(suggestion.range)
        }

        // Add model suggestions that don't overlap with system suggestions
        for modelSuggestion in modelSuggestions {
            let hasOverlap = processedRanges.contains { range in
                NSIntersectionRange(range, modelSuggestion.range).length > 0
            }

            if !hasOverlap {
                mergedSuggestions.append(modelSuggestion)
                processedRanges.insert(modelSuggestion.range)
            } else {
                // Merge candidates for overlapping suggestions
                if let index = mergedSuggestions.firstIndex(where: { $0.range == modelSuggestion.range }) {
                    let existingSuggestion = mergedSuggestions[index]
                    let mergedCandidates = Array(Set(existingSuggestion.candidates + modelSuggestion.candidates))

                    let mergedSuggestion = Suggestion(
                        word: existingSuggestion.word,
                        range: existingSuggestion.range,
                        context: existingSuggestion.context,
                        candidates: mergedCandidates,
                        source: "System+LocalModel"
                    )

                    mergedSuggestions[index] = mergedSuggestion
                }
            }
        }

        return mergedSuggestions.sorted { $0.range.location < $1.range.location }
    }

    func applyReplacement(text: inout String, for suggestion: Suggestion, with candidate: String) {
        let nsText = text as NSString
        let beforeRange = NSRange(location: 0, length: suggestion.range.location)
        let afterRange = NSRange(
            location: suggestion.range.location + suggestion.range.length,
            length: nsText.length - (suggestion.range.location + suggestion.range.length)
        )

        let beforeText = nsText.substring(with: beforeRange)
        let afterText = nsText.substring(with: afterRange)

        text = beforeText + candidate + afterText
    }

    func ignore(word: String) {
        ignoredWords.insert(word)
        spellChecker.ignoreWord(word, inSpellDocumentWithTag: 0)
    }

    func addToUserDictionary(word: String) {
        spellChecker.learnWord(word)
    }

    private func getContextRange(for range: NSRange, in text: NSString) -> NSRange {
        let contextLength = 40
        let start = max(0, range.location - contextLength)
        let end = min(text.length, range.location + range.length + contextLength)

        return NSRange(location: start, length: end - start)
    }

    func checkFullText(_ text: String, language: String? = nil) -> [Suggestion] {
        let systemSuggestions = scanSystem(text: text, language: language)
        let modelSuggestions = analyzeWithLocalModel(text: text, language: language)

        return merge(systemSuggestions, modelSuggestions)
    }
}

//
//  SpellService.swift
//  Spello
//
//  Created by eevv on 9/28/25.
//

import Foundation
import AppKit
import Combine

class SpellService: ObservableObject, SpellAnalyzing {
    @Published var isLocalModelEnabled: Bool = false
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

        // For synchronous operation, use mock suggestions
        // In production, you'd implement this as an async method
        return getMockLocalModelSuggestions(for: text)
    }

    // Async version for future use with real local models
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
            // Fallback to mock suggestions if local model fails
            return getMockLocalModelSuggestions(for: text)
        }
    }

    private func getMockLocalModelSuggestions(for text: String) -> [Suggestion] {
        let nsText = text as NSString
        var suggestions: [Suggestion] = []

        // Mock: Find common typos and suggest corrections
        let mockReplacements = [
            "teh": ["the"],
            "recieve": ["receive"],
            "seperate": ["separate"],
            "occured": ["occurred"],
            "definately": ["definitely"]
        ]

        for (typo, corrections) in mockReplacements {
            let searchRange = NSRange(location: 0, length: nsText.length)
            let range = nsText.range(of: typo, options: .caseInsensitive, range: searchRange)

            if range.location != NSNotFound {
                let contextRange = getContextRange(for: range, in: nsText)
                let context = nsText.substring(with: contextRange)

                let suggestion = Suggestion(
                    word: nsText.substring(with: range),
                    range: range,
                    context: context,
                    candidates: corrections,
                    source: "LocalModel"
                )

                suggestions.append(suggestion)
            }
        }

        return suggestions
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
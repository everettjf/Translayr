//
//  SpellServiceTests.swift
//  TranslayrTests
//
//  Created by eevv on 9/28/25.
//

import XCTest
@testable import Translayr

final class SpellServiceTests: XCTestCase {
    var spellService: SpellService!

    override func setUpWithError() throws {
        spellService = SpellService()
    }

    override func tearDownWithError() throws {
        spellService = nil
    }

    func testScanSystemWithMisspelledWords() throws {
        let text = "This is a test with some misspeled words and incorect spelling."
        let suggestions = spellService.scanSystem(text: text)

        XCTAssertFalse(suggestions.isEmpty, "Should find misspelled words")
        XCTAssertTrue(suggestions.count >= 2, "Should find at least 2 misspelled words")

        let misspelledWords = suggestions.map { $0.word.lowercased() }
        XCTAssertTrue(misspelledWords.contains("misspeled"), "Should detect 'misspeled'")
        XCTAssertTrue(misspelledWords.contains("incorect"), "Should detect 'incorect'")
    }

    func testScanSystemWithCorrectText() throws {
        let text = "This is a perfectly spelled sentence with no errors."
        let suggestions = spellService.scanSystem(text: text)

        XCTAssertTrue(suggestions.isEmpty, "Should not find any spelling errors in correct text")
    }

    func testLocalModelSuggestions() throws {
        spellService.isLocalModelEnabled = true
        let text = "I recieve the seperate definately message."
        let suggestions = spellService.analyzeWithLocalModel(text: text)

        XCTAssertFalse(suggestions.isEmpty, "Should find local model suggestions")

        let suggestedWords = suggestions.map { $0.word.lowercased() }
        XCTAssertTrue(suggestedWords.contains("recieve"), "Should detect 'recieve'")
        XCTAssertTrue(suggestedWords.contains("seperate"), "Should detect 'seperate'")
        XCTAssertTrue(suggestedWords.contains("definately"), "Should detect 'definately'")
    }

    func testLocalModelDisabled() throws {
        spellService.isLocalModelEnabled = false
        let text = "This has some recieve errors."
        let suggestions = spellService.analyzeWithLocalModel(text: text)

        XCTAssertTrue(suggestions.isEmpty, "Should not return suggestions when local model is disabled")
    }

    func testMergeSuggestions() throws {
        let systemSuggestion = Suggestion(
            word: "misspeled",
            range: NSRange(location: 0, length: 9),
            context: "misspeled word",
            candidates: ["misspelled"],
            source: "System"
        )

        let modelSuggestion = Suggestion(
            word: "recieve",
            range: NSRange(location: 20, length: 7),
            context: "recieve message",
            candidates: ["receive"],
            source: "LocalModel"
        )

        let overlappingSuggestion = Suggestion(
            word: "misspeled",
            range: NSRange(location: 0, length: 9),
            context: "misspeled word",
            candidates: ["misspelt", "mispelled"],
            source: "LocalModel"
        )

        let merged = spellService.merge([systemSuggestion], [modelSuggestion])
        XCTAssertEqual(merged.count, 2, "Should merge non-overlapping suggestions")

        let mergedWithOverlap = spellService.merge([systemSuggestion], [overlappingSuggestion])
        XCTAssertEqual(mergedWithOverlap.count, 1, "Should merge overlapping suggestions")
        XCTAssertTrue(mergedWithOverlap[0].candidates.contains("misspelled"), "Should contain system candidates")
        XCTAssertTrue(mergedWithOverlap[0].candidates.contains("misspelt"), "Should contain model candidates")
    }

    func testApplyReplacement() throws {
        var text = "This is a misspeled word."
        let suggestion = Suggestion(
            word: "misspeled",
            range: NSRange(location: 10, length: 9),
            context: "This is a misspeled word.",
            candidates: ["misspelled"],
            source: "System"
        )

        spellService.applyReplacement(text: &text, for: suggestion, with: "misspelled")
        XCTAssertEqual(text, "This is a misspelled word.", "Should correctly replace the misspelled word")
    }

    func testIgnoreWord() throws {
        let word = "customword"
        spellService.ignore(word: word)

        let text = "This contains customword which should be ignored."
        let suggestions = spellService.scanSystem(text: text)

        let ignoredWords = suggestions.map { $0.word }
        XCTAssertFalse(ignoredWords.contains(word), "Should ignore the specified word")
    }

    func testFullTextCheck() throws {
        let text = "This has misspeled words and recieve errors."
        let suggestions = spellService.checkFullText(text)

        XCTAssertFalse(suggestions.isEmpty, "Should find suggestions in full text check")

        let sources = Set(suggestions.map { $0.source })
        XCTAssertTrue(sources.contains("System"), "Should include system suggestions")

        spellService.isLocalModelEnabled = true
        let suggestionsWithModel = spellService.checkFullText(text)
        let sourcesWithModel = Set(suggestionsWithModel.map { $0.source })
        XCTAssertTrue(sourcesWithModel.contains("LocalModel") || sourcesWithModel.contains("System+LocalModel"),
                     "Should include local model suggestions when enabled")
    }

    func testContextExtraction() throws {
        let longText = """
        This is a very long text that contains multiple sentences and paragraphs.
        The purpose of this text is to test the context extraction functionality.
        We want to make sure that when we find a misspeled word, we extract the
        appropriate context around it without going beyond the text boundaries.
        """

        let suggestions = spellService.scanSystem(text: longText)
        XCTAssertFalse(suggestions.isEmpty, "Should find suggestions in long text")

        for suggestion in suggestions {
            XCTAssertFalse(suggestion.context.isEmpty, "Context should not be empty")
            XCTAssertTrue(suggestion.context.contains(suggestion.word), "Context should contain the misspelled word")
            XCTAssertLessOrThanOrEqual(suggestion.context.count, 100, "Context should be reasonably sized")
        }
    }

    func testMultipleOccurrences() throws {
        let text = "This recieve message. I recieve another recieve notification."
        spellService.isLocalModelEnabled = true
        let suggestions = spellService.checkFullText(text)

        let receiveErrors = suggestions.filter { $0.word.lowercased() == "recieve" }
        XCTAssertEqual(receiveErrors.count, 3, "Should find all three occurrences of 'recieve'")

        // Test that ranges don't overlap
        let ranges = receiveErrors.map { $0.range }
        for i in 0..<ranges.count {
            for j in (i+1)..<ranges.count {
                let intersection = NSIntersectionRange(ranges[i], ranges[j])
                XCTAssertEqual(intersection.length, 0, "Ranges should not overlap")
            }
        }
    }

    func testPerformanceOfLargeText() throws {
        // Generate a large text with multiple errors
        var largeText = ""
        for i in 0..<1000 {
            largeText += "This is sentence \(i) with some misspeled words and incorect spelling. "
        }

        measure {
            let _ = spellService.scanSystem(text: largeText)
        }
    }
}
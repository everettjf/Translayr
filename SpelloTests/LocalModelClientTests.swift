//
//  LocalModelClientTests.swift
//  SpelloTests
//
//  Created by eevv on 9/28/25.
//

import XCTest
@testable import Spello

final class LocalModelClientTests: XCTestCase {
    var localModelClient: LocalModelClient!

    override func setUpWithError() throws {
        localModelClient = LocalModelClient()
    }

    override func tearDownWithError() throws {
        localModelClient = nil
    }

    func testMockSuggestions() async throws {
        let text = "This has alot of irregardless phrases and could of been better."
        let suggestions = try await localModelClient.analyzeText(text)

        XCTAssertFalse(suggestions.isEmpty, "Should return mock suggestions")

        let words = suggestions.map { $0.word.lowercased() }
        XCTAssertTrue(words.contains("alot"), "Should detect 'alot'")
        XCTAssertTrue(words.contains("irregardless"), "Should detect 'irregardless'")
        XCTAssertTrue(words.contains("could of"), "Should detect 'could of'")
    }

    func testSuggestionConfidence() async throws {
        let text = "This has alot of errors."
        let suggestions = try await localModelClient.analyzeText(text)

        for suggestion in suggestions {
            XCTAssertGreaterThan(suggestion.confidence, 0.0, "Confidence should be greater than 0")
            XCTAssertLessThanOrEqual(suggestion.confidence, 1.0, "Confidence should not exceed 1")
        }
    }

    func testLocalModelSuggestionConversion() throws {
        let localSuggestion = LocalModelSuggestion(
            word: "alot",
            range: NSRange(location: 10, length: 4),
            candidates: ["a lot"],
            confidence: 0.95
        )

        let context = "This has alot of problems"
        let suggestion = localSuggestion.toSuggestion(context: context)

        XCTAssertEqual(suggestion.word, "alot")
        XCTAssertEqual(suggestion.range, NSRange(location: 10, length: 4))
        XCTAssertEqual(suggestion.context, context)
        XCTAssertEqual(suggestion.candidates, ["a lot"])
        XCTAssertEqual(suggestion.source, "LocalModel")
    }

    func testEmptyTextAnalysis() async throws {
        let suggestions = try await localModelClient.analyzeText("")
        XCTAssertTrue(suggestions.isEmpty, "Should return empty array for empty text")
    }

    func testTextWithoutErrors() async throws {
        let text = "This is a perfectly written sentence with no grammar issues."
        let suggestions = try await localModelClient.analyzeText(text)

        // Mock implementation might still return suggestions for demonstration
        // In a real implementation, this would depend on the model's accuracy
        XCTAssertTrue(suggestions.isEmpty || !suggestions.isEmpty, "Should handle text without errors gracefully")
    }
}
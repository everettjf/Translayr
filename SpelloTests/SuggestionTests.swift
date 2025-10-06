//
//  SuggestionTests.swift
//  SpelloTests
//
//  Created by eevv on 9/28/25.
//

import XCTest
@testable import Spello

final class SuggestionTests: XCTestCase {

    func testSuggestionEquality() throws {
        let suggestion1 = Suggestion(
            word: "test",
            range: NSRange(location: 0, length: 4),
            context: "test word",
            candidates: ["best", "rest"],
            source: "System"
        )

        let suggestion2 = Suggestion(
            word: "test",
            range: NSRange(location: 0, length: 4),
            context: "different context",
            candidates: ["different", "candidates"],
            source: "LocalModel"
        )

        let suggestion3 = Suggestion(
            word: "different",
            range: NSRange(location: 0, length: 4),
            context: "test word",
            candidates: ["best", "rest"],
            source: "System"
        )

        XCTAssertEqual(suggestion1, suggestion2, "Suggestions with same word and range should be equal")
        XCTAssertNotEqual(suggestion1, suggestion3, "Suggestions with different words should not be equal")
    }

    func testSuggestionInitialization() throws {
        let word = "misspelled"
        let range = NSRange(location: 5, length: 10)
        let context = "This is misspelled word"
        let candidates = ["misspelled", "miss spelled"]
        let source = "System"

        let suggestion = Suggestion(
            word: word,
            range: range,
            context: context,
            candidates: candidates,
            source: source
        )

        XCTAssertEqual(suggestion.word, word)
        XCTAssertEqual(suggestion.range, range)
        XCTAssertEqual(suggestion.context, context)
        XCTAssertEqual(suggestion.candidates, candidates)
        XCTAssertEqual(suggestion.source, source)
        XCTAssertNotNil(suggestion.id)
    }

    func testUniqueIdentifiers() throws {
        let suggestion1 = Suggestion(
            word: "test",
            range: NSRange(location: 0, length: 4),
            context: "test word",
            candidates: ["best"],
            source: "System"
        )

        let suggestion2 = Suggestion(
            word: "test",
            range: NSRange(location: 0, length: 4),
            context: "test word",
            candidates: ["best"],
            source: "System"
        )

        XCTAssertNotEqual(suggestion1.id, suggestion2.id, "Each suggestion should have a unique ID")
    }
}
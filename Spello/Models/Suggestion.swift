//
//  Suggestion.swift
//  Spello
//
//  Created by XNU on 9/28/25.
//

import Foundation

struct Suggestion: Identifiable, Equatable, Hashable {
    let id: UUID
    let word: String
    let range: NSRange
    let context: String
    let candidates: [String]
    let source: String

    init(word: String, range: NSRange, context: String, candidates: [String], source: String) {
        self.id = UUID()
        self.word = word
        self.range = range
        self.context = context
        self.candidates = candidates
        self.source = source
    }

    static func == (lhs: Suggestion, rhs: Suggestion) -> Bool {
        return lhs.word == rhs.word &&
               lhs.range.location == rhs.range.location &&
               lhs.range.length == rhs.range.length
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(word)
        hasher.combine(range.location)
        hasher.combine(range.length)
    }
}

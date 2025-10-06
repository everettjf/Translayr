//
//  SpellAnalyzing.swift
//  Spello
//
//  Created by eevv on 9/28/25.
//

import Foundation

protocol SpellAnalyzing {
    func scanSystem(text: String, language: String?) -> [Suggestion]
    func analyzeWithLocalModel(text: String, language: String?) -> [Suggestion]
    func merge(_ a: [Suggestion], _ b: [Suggestion]) -> [Suggestion]
    func applyReplacement(text: inout String, for suggestion: Suggestion, with candidate: String)
    func ignore(word: String)
    func addToUserDictionary(word: String)
}
//
//  LocalModelClient.swift
//  Spello
//
//  Created by eevv on 9/28/25.
//

import Foundation

protocol LocalModelClientProtocol {
    func analyzeText(_ text: String, language: String?) async throws -> [LocalModelSuggestion]
}

struct LocalModelSuggestion {
    let word: String
    let range: NSRange
    let candidates: [String]
    let confidence: Float
}

class LocalModelClient: LocalModelClientProtocol {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: String = "http://127.0.0.1:8080") {
        self.baseURL = URL(string: baseURL)!
        self.session = URLSession.shared
    }

    func analyzeText(_ text: String, language: String? = nil) async throws -> [LocalModelSuggestion] {
        // For now, return mock data since we don't have a real local model server
        // In production, this would make an HTTP request to the local model endpoint
        return await getMockSuggestions(for: text)
    }

    private func getMockSuggestions(for text: String) async -> [LocalModelSuggestion] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        let nsText = text as NSString
        var suggestions: [LocalModelSuggestion] = []

        // Mock: Advanced grammar and style suggestions
        let advancedSuggestions: [(String, [String], Float)] = [
            ("alot", ["a lot"], 0.95),
            ("irregardless", ["regardless"], 0.90),
            ("could of", ["could have"], 0.98),
            ("should of", ["should have"], 0.98),
            ("would of", ["would have"], 0.98),
            ("there performance", ["their performance"], 0.85),
            ("its been", ["it's been"], 0.80),
            ("your welcome", ["you're welcome"], 0.92),
            ("loose weight", ["lose weight"], 0.88),
            ("effect change", ["affect change"], 0.75)
        ]

        for (phrase, corrections, confidence) in advancedSuggestions {
            let searchRange = NSRange(location: 0, length: nsText.length)
            let range = nsText.range(of: phrase, options: .caseInsensitive, range: searchRange)

            if range.location != NSNotFound {
                let suggestion = LocalModelSuggestion(
                    word: nsText.substring(with: range),
                    range: range,
                    candidates: corrections,
                    confidence: confidence
                )
                suggestions.append(suggestion)
            }
        }

        return suggestions
    }

    // Future implementation for real HTTP requests
    private func makeHTTPRequest(text: String, language: String?) async throws -> [LocalModelSuggestion] {
        let endpoint = baseURL.appendingPathComponent("analyze")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = [
            "text": text,
            "language": language ?? "auto",
            "task": "spell_check"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LocalModelError.serverError
        }

        let result = try JSONDecoder().decode(LocalModelResponse.self, from: data)
        return result.suggestions.map { suggestion in
            LocalModelSuggestion(
                word: suggestion.word,
                range: NSRange(location: suggestion.start, length: suggestion.length),
                candidates: suggestion.candidates,
                confidence: suggestion.confidence
            )
        }
    }
}

enum LocalModelError: Error {
    case serverError
    case invalidResponse
    case networkError
}

// Response models for HTTP API
struct LocalModelResponse: Codable {
    let suggestions: [APISpellSuggestion]
}

struct APISpellSuggestion: Codable {
    let word: String
    let start: Int
    let length: Int
    let candidates: [String]
    let confidence: Float
}

// Extension to convert LocalModelSuggestion to Suggestion
extension LocalModelSuggestion {
    func toSuggestion(context: String) -> Suggestion {
        return Suggestion(
            word: word,
            range: range,
            context: context,
            candidates: candidates,
            source: "LocalModel"
        )
    }
}
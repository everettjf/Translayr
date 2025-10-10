//
//  LocalModelClient.swift
//  Spello
//
//  Created by XNU on 9/28/25.
//

import Foundation
import Ollama

protocol LocalModelClientProtocol {
    func analyzeText(_ text: String, language: String?) async throws -> [LocalModelSuggestion]
    func translateText(_ text: String) async throws -> String
}

struct LocalModelSuggestion {
    let word: String
    let range: NSRange
    let candidates: [String]
    let confidence: Float
}

class LocalModelClient: LocalModelClientProtocol {
    private let ollamaClient: Ollama.Client
    private let modelName: String

    init(
        host: String = OllamaConfig.host,
        port: Int = OllamaConfig.port,
        modelName: String = OllamaConfig.defaultModel
    ) {
        let hostURL = URL(string: "\(host):\(port)")!
        self.ollamaClient = Ollama.Client(host: hostURL)
        self.modelName = modelName
    }

    func analyzeText(_ text: String, language: String? = nil) async throws -> [LocalModelSuggestion] {
        let sourceLanguage = LanguageConfig.sourceLanguage
        print("LocalModelClient: analyzeText called")
        print("Text contains \(sourceLanguage.displayName): \(containsTargetLanguage(text))")

        // 检测文本是否包含目标语言
        if containsTargetLanguage(text) {
            return try await analyzeTargetLanguageText(text)
        }

        print("No \(sourceLanguage.displayName) detected, returning empty suggestions")
        // 对于非目标语言文本，返回空数组
        return []
    }

    private func containsTargetLanguage(_ text: String) -> Bool {
        let language = LanguageConfig.sourceLanguage
        let languageRange = text.range(of: language.unicodePattern, options: .regularExpression)
        return languageRange != nil
    }

    private func analyzeTargetLanguageText(_ text: String) async throws -> [LocalModelSuggestion] {
        let language = LanguageConfig.sourceLanguage
        var suggestions: [LocalModelSuggestion] = []

        print("=== Analyzing \(language.displayName) text ===")
        print("Text: \(text)")

        // 分词：将文本分成词或短语
        let words = segmentText(text)
        print("Segmented into \(words.count) words")

        for word in words {
            // 跳过纯英文或数字
            if !containsTargetLanguage(word.text) {
                print("Skipping non-\(language.displayName) word: '\(word.text)'")
                continue
            }

            print("Translating: '\(word.text)'")

            // 翻译目标语言到英文
            do {
                let translation = try await translateText(word.text)
                print("Translation result: '\(word.text)' -> '\(translation)'")

                if !translation.isEmpty {
                    let suggestion = LocalModelSuggestion(
                        word: word.text,
                        range: word.range,
                        candidates: [translation],
                        confidence: 0.9
                    )
                    suggestions.append(suggestion)
                }
            } catch {
                // 如果翻译失败，跳过这个词
                print("Translation failed for '\(word.text)': \(error)")
            }
        }

        print("Generated \(suggestions.count) translation suggestions")
        return suggestions
    }

    func translateText(_ text: String) async throws -> String {
        let sourceLanguage = LanguageConfig.sourceLanguage
        let targetLanguage = LanguageConfig.targetLanguage
        let prompt = sourceLanguage.translationPrompt(for: text, targetLanguage: targetLanguage)

        do {
            guard let modelID = Model.ID(rawValue: modelName) else {
                throw LocalModelError.invalidModelName
            }

            // 使用 Ollama 生成翻译
            var fullResponse = ""

            if OllamaConfig.streamingEnabled {
                // 使用流式 API
                let stream = ollamaClient.generateStream(
                    model: modelID,
                    prompt: prompt,
                    options: [
                        "temperature": .double(OllamaConfig.temperature),
                        "top_p": .double(OllamaConfig.topP),
                        "top_k": .int(OllamaConfig.topK)
                    ]
                )

                for try await chunk in stream {
                    fullResponse += chunk.response
                }
            } else {
                // 使用非流式 API
                let response = try await ollamaClient.generate(
                    model: modelID,
                    prompt: prompt,
                    options: [
                        "temperature": .double(OllamaConfig.temperature),
                        "top_p": .double(OllamaConfig.topP),
                        "top_k": .int(OllamaConfig.topK)
                    ]
                )
                fullResponse = response.response
            }

            // 清理响应：移除前后空白，并将内部换行符替换为空格
            var cleaned = fullResponse
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")

            // 递归合并多余空格
            while cleaned.contains("  ") {
                cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
            }

            return cleaned

        } catch {
            print("Ollama error: \(error)")
            throw LocalModelError.networkError
        }
    }

    private func segmentText(_ text: String) -> [(text: String, range: NSRange)] {
        let language = LanguageConfig.sourceLanguage
        let nsText = text as NSString
        var segments: [(text: String, range: NSRange)] = []

        // 提取连续的目标语言字符组成的词组
        let pattern = "[\(language.unicodePattern)]{\(language.minWordLength),}"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("Failed to create regex for \(language.displayName) segmentation")
            return segments
        }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        print("Found \(matches.count) \(language.displayName) segments in text")

        for match in matches {
            let matchText = nsText.substring(with: match.range)
            print("\(language.displayName) segment: '\(matchText)' at range \(match.range.location)-\(match.range.location + match.range.length)")
            segments.append((text: matchText, range: match.range))
        }

        return segments
    }
}

enum LocalModelError: Error {
    case serverError
    case invalidResponse
    case networkError
    case modelNotFound
    case invalidModelName
}

// Extension to convert LocalModelSuggestion to Suggestion
extension LocalModelSuggestion {
    func toSuggestion(context: String) -> Suggestion {
        return Suggestion(
            word: word,
            range: range,
            context: context,
            candidates: candidates,
            source: "AI Translation"
        )
    }
}

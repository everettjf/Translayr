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
    func translateChineseToEnglish(_ text: String) async throws -> String
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
        print("LocalModelClient: analyzeText called")
        print("Text contains Chinese: \(containsChinese(text))")

        // 检测文本是否包含中文
        if containsChinese(text) {
            return try await analyzeChineseText(text)
        }

        print("No Chinese detected, returning empty suggestions")
        // 对于非中文文本，使用基本的拼写检查
        return []
    }

    private func containsChinese(_ text: String) -> Bool {
        let chineseRange = text.range(of: "\\p{Han}", options: .regularExpression)
        return chineseRange != nil
    }

    private func analyzeChineseText(_ text: String) async throws -> [LocalModelSuggestion] {
        var suggestions: [LocalModelSuggestion] = []
        let nsText = text as NSString

        print("=== Analyzing Chinese text ===")
        print("Text: \(text)")

        // 分词：将文本分成词或短语
        let words = segmentChineseText(text)
        print("Segmented into \(words.count) words")

        for word in words {
            // 跳过纯英文或数字
            if !containsChinese(word.text) {
                print("Skipping non-Chinese word: '\(word.text)'")
                continue
            }

            print("Translating: '\(word.text)'")

            // 翻译中文词到英文
            do {
                let translation = try await translateChineseToEnglish(word.text)
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

    func translateChineseToEnglish(_ text: String) async throws -> String {
        let prompt = """
        Translate the following Chinese text to English. Only provide the translation, no explanation or additional text.

        Chinese: \(text)
        English:
        """

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

            // 清理响应
            let cleaned = fullResponse.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned

        } catch {
            print("Ollama error: \(error)")
            throw LocalModelError.networkError
        }
    }

    private func segmentChineseText(_ text: String) -> [(text: String, range: NSRange)] {
        let nsText = text as NSString
        var segments: [(text: String, range: NSRange)] = []

        // 改进的中文分词：提取连续的中文字符组成的词组
        // 使用更智能的分词策略：2-4个字的中文词组
        let pattern = "[\\p{Han}]{2,}"  // 至少2个汉字组成一个词

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("Failed to create regex for Chinese segmentation")
            return segments
        }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        print("Found \(matches.count) Chinese segments in text")

        for match in matches {
            let matchText = nsText.substring(with: match.range)
            print("Chinese segment: '\(matchText)' at range \(match.range.location)-\(match.range.location + match.range.length)")
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

//
//  SystemServiceProvider.swift
//  Spello
//
//  系统级服务提供者 - 允许在其他应用中使用翻译功能
//

import AppKit
import Foundation

@MainActor
class SystemServiceProvider: NSObject {
    static let shared = SystemServiceProvider()
    private let localModelClient = LocalModelClient()

    override init() {
        super.init()
        NSApp.servicesProvider = self
    }

    // MARK: - Service Methods

    /// 翻译选中的文本（中文到英文）
    /// 这个方法会在用户从系统服务菜单选择 "Translate to English" 时被调用
    @objc func translateToEnglish(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        print("=== System Service: translateToEnglish called ===")

        guard let selectedText = pasteboard.string(forType: .string) else {
            print("No text found in pasteboard")
            return
        }

        print("Selected text: \(selectedText)")

        // 使用 Task 来处理异步翻译
        Task {
            do {
                let translation = await translateText(selectedText)

                // 将翻译结果写回 pasteboard
                await MainActor.run {
                    pasteboard.clearContents()
                    pasteboard.setString(translation, forType: .string)
                    print("Translation completed: \(translation)")
                }
            }
        }
    }

    /// 获取中文词组的翻译建议
    @objc func getTranslationSuggestions(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        print("=== System Service: getTranslationSuggestions called ===")

        guard let selectedText = pasteboard.string(forType: .string) else {
            print("No text found in pasteboard")
            return
        }

        print("Selected text: \(selectedText)")

        Task {
            let suggestions = await getTranslations(selectedText)

            await MainActor.run {
                // 创建一个包含多个建议的字符串
                let suggestionsText = suggestions.joined(separator: "\n")
                pasteboard.clearContents()
                pasteboard.setString(suggestionsText, forType: .string)
                print("Suggestions: \(suggestionsText)")
            }
        }
    }

    // MARK: - Helper Methods

    private func translateText(_ text: String) async -> String {
        print("Translating text: \(text)")

        // 检测是否包含中文
        guard containsChinese(text) else {
            print("No Chinese detected, returning original text")
            return text
        }

        do {
            // 直接翻译整个文本
            let translation = try await localModelClient.translateChineseToEnglish(text)
            return translation
        } catch {
            print("Translation error: \(error)")
            return text
        }
    }

    private func getTranslations(_ text: String) async -> [String] {
        print("Getting translations for: \(text)")

        guard containsChinese(text) else {
            return [text]
        }

        do {
            let suggestions = try await localModelClient.analyzeText(text, language: nil)
            return suggestions.flatMap { $0.candidates }
        } catch {
            print("Error getting translations: \(error)")
            return [text]
        }
    }

    private func containsChinese(_ text: String) -> Bool {
        let chineseRange = text.range(of: "\\p{Han}", options: .regularExpression)
        return chineseRange != nil
    }
}

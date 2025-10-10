//
//  LanguageConfig.swift
//  Spello
//
//  语言配置 - 定义支持的检测语言
//

import Foundation

/// 支持的语言类型
enum DetectionLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case russian = "ru"
    case arabic = "ar"

    var id: String { rawValue }

    /// 语言显示名称
    var displayName: String {
        switch self {
        case .chinese: return "中文 (Chinese)"
        case .japanese: return "日本語 (Japanese)"
        case .korean: return "한국어 (Korean)"
        case .russian: return "Русский (Russian)"
        case .arabic: return "العربية (Arabic)"
        }
    }

    /// 语言的 Unicode 正则表达式模式
    var unicodePattern: String {
        switch self {
        case .chinese:
            return "\\p{Han}" // 中文字符
        case .japanese:
            return "[\\p{Hiragana}\\p{Katakana}\\p{Han}]" // 平假名、片假名、汉字
        case .korean:
            return "\\p{Hangul}" // 韩文字符
        case .russian:
            return "\\p{Cyrillic}" // 西里尔字符
        case .arabic:
            return "\\p{Arabic}" // 阿拉伯字符
        }
    }

    /// 目标翻译语言（默认翻译到英文）
    var targetLanguage: String {
        return "English"
    }

    /// 翻译提示词模板
    func translationPrompt(for text: String) -> String {
        return """
        Translate the following \(displayName) text to \(targetLanguage). Only provide the translation, no explanation or additional text.

        \(displayName): \(text)
        \(targetLanguage):
        """
    }

    /// 最小检测词组长度
    var minWordLength: Int {
        switch self {
        case .chinese, .japanese:
            return 2
        case .korean:
            return 2
        case .russian, .arabic:
            return 3 // 俄语和阿拉伯语单词通常更长
        }
    }
}

/// 语言检测配置管理器
struct LanguageConfig {
    /// 用户选择的检测语言（存储在 UserDefaults）
    static var detectionLanguage: DetectionLanguage {
        get {
            if let savedLang = UserDefaults.standard.string(forKey: "detectionLanguage"),
               let language = DetectionLanguage(rawValue: savedLang) {
                return language
            }
            return .chinese // 默认为中文
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "detectionLanguage")
        }
    }
}

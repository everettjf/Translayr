//
//  LanguageConfig.swift
//  Spello
//
//  语言配置 - 定义支持的检测语言
//

import Foundation

/// 通用语言类型（用于检测和目标翻译）
/// 世界上使用人数最多的10种语言
enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh"
    case hindi = "hi"
    case spanish = "es"
    case french = "fr"
    case arabic = "ar"
    case bengali = "bn"
    case russian = "ru"
    case portuguese = "pt"
    case indonesian = "id"

    var id: String { rawValue }

    /// 语言显示名称
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文 (Chinese)"
        case .hindi: return "हिन्दी (Hindi)"
        case .spanish: return "Español (Spanish)"
        case .french: return "Français (French)"
        case .arabic: return "العربية (Arabic)"
        case .bengali: return "বাংলা (Bengali)"
        case .russian: return "Русский (Russian)"
        case .portuguese: return "Português (Portuguese)"
        case .indonesian: return "Bahasa Indonesia (Indonesian)"
        }
    }

    /// 语言的 Unicode 正则表达式模式
    var unicodePattern: String {
        switch self {
        case .english:
            return "[a-zA-Z]" // 英语标准拉丁字母
        case .chinese:
            return "\\p{Han}" // 中文字符
        case .hindi:
            return "\\p{Devanagari}" // 天城文（印地语）
        case .spanish:
            return "[áéíóúüñÁÉÍÓÚÜÑ¿¡a-zA-Z]" // 西班牙语特殊字符
        case .french:
            return "[àâäæçéèêëïîôùûüÿœÀÂÄÆÇÉÈÊËÏÎÔÙÛÜŸŒa-zA-Z]" // 法语特殊字符
        case .arabic:
            return "\\p{Arabic}" // 阿拉伯字符
        case .bengali:
            return "\\p{Bengali}" // 孟加拉字符
        case .russian:
            return "\\p{Cyrillic}" // 西里尔字符
        case .portuguese:
            return "[áâãàçéêíóôõúüÁÂÃÀÇÉÊÍÓÔÕÚÜa-zA-Z]" // 葡萄牙语特殊字符
        case .indonesian:
            return "[a-zA-Z]" // 印尼语使用标准拉丁字母
        }
    }

    /// 最小检测词组长度
    var minWordLength: Int {
        switch self {
        case .chinese:
            return 2
        case .hindi, .bengali:
            return 2
        case .arabic, .russian:
            return 3
        case .spanish, .french, .portuguese:
            return 3
        case .english, .indonesian:
            return 4 // 标准拉丁字母，需要更长的词来确定
        }
    }

    /// 翻译提示词模板
    func translationPrompt(for text: String, targetLanguage: Language) -> String {
        return """
        Translate the following \(displayName) text to \(targetLanguage.displayName). Only provide the translation, no explanation or additional text.

        \(displayName): \(text)
        \(targetLanguage.displayName):
        """
    }
}

/// 语言检测配置管理器
struct LanguageConfig {
    /// 用户选择的源语言（检测语言）
    static var sourceLanguage: Language {
        get {
            if let savedLang = UserDefaults.standard.string(forKey: "sourceLanguage"),
               let language = Language(rawValue: savedLang) {
                return language
            }
            return .chinese // 默认为中文
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "sourceLanguage")
        }
    }

    /// 用户选择的目标语言（翻译到）
    static var targetLanguage: Language {
        get {
            if let savedLang = UserDefaults.standard.string(forKey: "targetLanguage"),
               let language = Language(rawValue: savedLang) {
                return language
            }
            return .english // 默认为英语
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "targetLanguage")
        }
    }

    /// 检查是否选择了相同的源语言和目标语言
    static var isSameLanguage: Bool {
        return sourceLanguage == targetLanguage
    }
}

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
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case hindi = "hi"
    case thai = "th"
    case vietnamese = "vi"
    case turkish = "tr"
    case polish = "pl"
    case dutch = "nl"
    case swedish = "sv"
    case greek = "el"
    case hebrew = "he"
    case indonesian = "id"

    var id: String { rawValue }

    /// 语言显示名称
    var displayName: String {
        switch self {
        case .chinese: return "中文 (Chinese)"
        case .japanese: return "日本語 (Japanese)"
        case .korean: return "한국어 (Korean)"
        case .russian: return "Русский (Russian)"
        case .arabic: return "العربية (Arabic)"
        case .spanish: return "Español (Spanish)"
        case .french: return "Français (French)"
        case .german: return "Deutsch (German)"
        case .italian: return "Italiano (Italian)"
        case .portuguese: return "Português (Portuguese)"
        case .hindi: return "हिन्दी (Hindi)"
        case .thai: return "ไทย (Thai)"
        case .vietnamese: return "Tiếng Việt (Vietnamese)"
        case .turkish: return "Türkçe (Turkish)"
        case .polish: return "Polski (Polish)"
        case .dutch: return "Nederlands (Dutch)"
        case .swedish: return "Svenska (Swedish)"
        case .greek: return "Ελληνικά (Greek)"
        case .hebrew: return "עברית (Hebrew)"
        case .indonesian: return "Bahasa Indonesia (Indonesian)"
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
        case .spanish:
            return "[áéíóúüñÁÉÍÓÚÜÑ¿¡a-zA-Z]" // 西班牙语特殊字符
        case .french:
            return "[àâäæçéèêëïîôùûüÿœÀÂÄÆÇÉÈÊËÏÎÔÙÛÜŸŒa-zA-Z]" // 法语特殊字符
        case .german:
            return "[äöüßÄÖÜa-zA-Z]" // 德语特殊字符
        case .italian:
            return "[àèéìíîòóùúÀÈÉÌÍÎÒÓÙÚa-zA-Z]" // 意大利语特殊字符
        case .portuguese:
            return "[áâãàçéêíóôõúüÁÂÃÀÇÉÊÍÓÔÕÚÜa-zA-Z]" // 葡萄牙语特殊字符
        case .hindi:
            return "\\p{Devanagari}" // 天城文（印地语、梵语等）
        case .thai:
            return "\\p{Thai}" // 泰语字符
        case .vietnamese:
            return "[aăâeêioôơuưyáắấéếíóốớúứýàằầèềìòồờùừỳảẳẩẻểỉỏổởủửỷãẵẫẽễĩõỗỡũữỹạặậẹệịọộợụựỵđAĂÂEÊIOÔƠUƯYÁẮẤÉẾÍÓỐỚÚỨÝÀẰẦÈỀÌÒỒỜÙỪỲẢẲẨẺỂỈỎỔỞỦỬỶÃẴẪẼỄĨÕỖỠŨỮỸẠẶẬẸỆỊỌỘỢỤỰỴĐ]" // 越南语声调字符
        case .turkish:
            return "[çğıİöşüÇĞÖŞÜa-zA-Z]" // 土耳其语特殊字符
        case .polish:
            return "[ąćęłńóśźżĄĆĘŁŃÓŚŹŻa-zA-Z]" // 波兰语特殊字符
        case .dutch:
            return "[áàâäéèêëíìîïóòôöúùûüÁÀÂÄÉÈÊËÍÌÎÏÓÒÔÖÚÙÛÜa-zA-Z]" // 荷兰语特殊字符
        case .swedish:
            return "[åäöÅÄÖa-zA-Z]" // 瑞典语特殊字符
        case .greek:
            return "\\p{Greek}" // 希腊字符
        case .hebrew:
            return "\\p{Hebrew}" // 希伯来字符
        case .indonesian:
            return "[a-zA-Z]" // 印尼语使用标准拉丁字母
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
            return 3
        case .spanish, .french, .german, .italian, .portuguese:
            return 3 // 拉丁语系通常需要更长的词来确定语言
        case .hindi, .thai:
            return 2
        case .vietnamese:
            return 3
        case .turkish, .polish, .dutch, .swedish:
            return 3 // 拉丁字母变体语言
        case .greek, .hebrew:
            return 2 // 独特字母系统
        case .indonesian:
            return 4 // 标准拉丁字母，需要更长的词来确定
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

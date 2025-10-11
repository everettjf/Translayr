//
//  ColorConfig.swift
//  Spello
//
//  颜色配置 - 定义下划线可用的颜色
//

import Foundation
import AppKit

/// 下划线颜色配置
struct UnderlineColor: Identifiable, Equatable {
    let id: String
    let name: String        // 颜色名称
    let hex: String         // 十六进制颜色码
    let displayName: String // 显示名称（中英文）

    /// 转换为 NSColor
    var nsColor: NSColor {
        return NSColor(hex: hex) ?? .red
    }
}

/// 预定义的下划线颜色列表
struct UnderlineColors {
    /// 所有可用的颜色（100种精选颜色）
    static let allColors: [UnderlineColor] = [
        // 红色系 (10)
        UnderlineColor(id: "red1", name: "Red", hex: "#FF3B30", displayName: "Red"),
        UnderlineColor(id: "red2", name: "Crimson", hex: "#DC143C", displayName: "Crimson"),
        UnderlineColor(id: "red3", name: "Scarlet", hex: "#FF2400", displayName: "Scarlet"),
        UnderlineColor(id: "red4", name: "Ruby", hex: "#E0115F", displayName: "Ruby"),
        UnderlineColor(id: "red5", name: "Cherry", hex: "#DE3163", displayName: "Cherry"),
        UnderlineColor(id: "red6", name: "Burgundy", hex: "#800020", displayName: "Burgundy"),
        UnderlineColor(id: "red7", name: "Maroon", hex: "#B03060", displayName: "Maroon"),
        UnderlineColor(id: "red8", name: "Brick", hex: "#CB4154", displayName: "Brick"),
        UnderlineColor(id: "red9", name: "Fire", hex: "#FE4C40", displayName: "Fire"),
        UnderlineColor(id: "red10", name: "Rose", hex: "#FF007F", displayName: "Rose"),

        // 橙色系 (10)
        UnderlineColor(id: "orange1", name: "Orange", hex: "#FF9500", displayName: "Orange"),
        UnderlineColor(id: "orange2", name: "Tangerine", hex: "#FF8C00", displayName: "Tangerine"),
        UnderlineColor(id: "orange3", name: "Coral", hex: "#FF7F50", displayName: "Coral"),
        UnderlineColor(id: "orange4", name: "Peach", hex: "#FFB374", displayName: "Peach"),
        UnderlineColor(id: "orange5", name: "Apricot", hex: "#FBCEB1", displayName: "Apricot"),
        UnderlineColor(id: "orange6", name: "Salmon", hex: "#FA8072", displayName: "Salmon"),
        UnderlineColor(id: "orange7", name: "Amber", hex: "#FFBF00", displayName: "Amber"),
        UnderlineColor(id: "orange8", name: "Sunset", hex: "#FD5E53", displayName: "Sunset"),
        UnderlineColor(id: "orange9", name: "Rust", hex: "#B7410E", displayName: "Rust"),
        UnderlineColor(id: "orange10", name: "Copper", hex: "#B87333", displayName: "Copper"),

        // 黄色系 (10)
        UnderlineColor(id: "yellow1", name: "Yellow", hex: "#FFCC00", displayName: "Yellow"),
        UnderlineColor(id: "yellow2", name: "Gold", hex: "#FFD700", displayName: "Gold"),
        UnderlineColor(id: "yellow3", name: "Lemon", hex: "#FFF44F", displayName: "Lemon"),
        UnderlineColor(id: "yellow4", name: "Canary", hex: "#FFEF00", displayName: "Canary"),
        UnderlineColor(id: "yellow5", name: "Mustard", hex: "#FFDB58", displayName: "Mustard"),
        UnderlineColor(id: "yellow6", name: "Cream", hex: "#FFFDD0", displayName: "Cream"),
        UnderlineColor(id: "yellow7", name: "Honey", hex: "#FFC30B", displayName: "Honey"),
        UnderlineColor(id: "yellow8", name: "Butter", hex: "#FFFACD", displayName: "Butter"),
        UnderlineColor(id: "yellow9", name: "Khaki", hex: "#C3B091", displayName: "Khaki"),
        UnderlineColor(id: "yellow10", name: "Sand", hex: "#C2B280", displayName: "Sand"),

        // 绿色系 (10)
        UnderlineColor(id: "green1", name: "Green", hex: "#34C759", displayName: "Green"),
        UnderlineColor(id: "green2", name: "Lime", hex: "#32CD32", displayName: "Lime"),
        UnderlineColor(id: "green3", name: "Forest", hex: "#228B22", displayName: "Forest"),
        UnderlineColor(id: "green4", name: "Emerald", hex: "#50C878", displayName: "Emerald"),
        UnderlineColor(id: "green5", name: "Mint", hex: "#3EB489", displayName: "Mint"),
        UnderlineColor(id: "green6", name: "Jade", hex: "#00A86B", displayName: "Jade"),
        UnderlineColor(id: "green7", name: "Olive", hex: "#808000", displayName: "Olive"),
        UnderlineColor(id: "green8", name: "Sage", hex: "#9DC183", displayName: "Sage"),
        UnderlineColor(id: "green9", name: "Pine", hex: "#01796F", displayName: "Pine"),
        UnderlineColor(id: "green10", name: "Grass", hex: "#7CFC00", displayName: "Grass"),

        // 蓝色系 (10)
        UnderlineColor(id: "blue1", name: "Blue", hex: "#007AFF", displayName: "Blue"),
        UnderlineColor(id: "blue2", name: "Azure", hex: "#007FFF", displayName: "Azure"),
        UnderlineColor(id: "blue3", name: "Navy", hex: "#000080", displayName: "Navy"),
        UnderlineColor(id: "blue4", name: "Royal", hex: "#4169E1", displayName: "Royal"),
        UnderlineColor(id: "blue5", name: "Cobalt", hex: "#0047AB", displayName: "Cobalt"),
        UnderlineColor(id: "blue6", name: "Sapphire", hex: "#0F52BA", displayName: "Sapphire"),
        UnderlineColor(id: "blue7", name: "Ocean", hex: "#4F42B5", displayName: "Ocean"),
        UnderlineColor(id: "blue8", name: "Steel", hex: "#4682B4", displayName: "Steel"),
        UnderlineColor(id: "blue9", name: "Denim", hex: "#1560BD", displayName: "Denim"),
        UnderlineColor(id: "blue10", name: "Ice", hex: "#00FFFF", displayName: "Ice"),

        // 青色系 (10)
        UnderlineColor(id: "cyan1", name: "Cyan", hex: "#00CED1", displayName: "Cyan"),
        UnderlineColor(id: "cyan2", name: "Teal", hex: "#008080", displayName: "Teal"),
        UnderlineColor(id: "cyan3", name: "Turquoise", hex: "#40E0D0", displayName: "Turquoise"),
        UnderlineColor(id: "cyan4", name: "Aqua", hex: "#00FFFF", displayName: "Aqua"),
        UnderlineColor(id: "cyan5", name: "Aquamarine", hex: "#7FFFD4", displayName: "Aquamarine"),
        UnderlineColor(id: "cyan6", name: "Sky", hex: "#87CEEB", displayName: "Sky"),
        UnderlineColor(id: "cyan7", name: "Peacock", hex: "#33A1C9", displayName: "Peacock"),
        UnderlineColor(id: "cyan8", name: "Caribbean", hex: "#00CCCC", displayName: "Caribbean"),
        UnderlineColor(id: "cyan9", name: "Lagoon", hex: "#00A99D", displayName: "Lagoon"),
        UnderlineColor(id: "cyan10", name: "Pool", hex: "#66CDAA", displayName: "Pool"),

        // 紫色系 (10)
        UnderlineColor(id: "purple1", name: "Purple", hex: "#AF52DE", displayName: "Purple"),
        UnderlineColor(id: "purple2", name: "Violet", hex: "#8B00FF", displayName: "Violet"),
        UnderlineColor(id: "purple3", name: "Lavender", hex: "#B57EDC", displayName: "Lavender"),
        UnderlineColor(id: "purple4", name: "Plum", hex: "#8E4585", displayName: "Plum"),
        UnderlineColor(id: "purple5", name: "Orchid", hex: "#DA70D6", displayName: "Orchid"),
        UnderlineColor(id: "purple6", name: "Magenta", hex: "#FF00FF", displayName: "Magenta"),
        UnderlineColor(id: "purple7", name: "Amethyst", hex: "#9966CC", displayName: "Amethyst"),
        UnderlineColor(id: "purple8", name: "Lilac", hex: "#C8A2C8", displayName: "Lilac"),
        UnderlineColor(id: "purple9", name: "Mauve", hex: "#E0B0FF", displayName: "Mauve"),
        UnderlineColor(id: "purple10", name: "Grape", hex: "#6F2DA8", displayName: "Grape"),

        // 粉色系 (10)
        UnderlineColor(id: "pink1", name: "Pink", hex: "#FF2D55", displayName: "Pink"),
        UnderlineColor(id: "pink2", name: "HotPink", hex: "#FF69B4", displayName: "Hot Pink"),
        UnderlineColor(id: "pink3", name: "Fuchsia", hex: "#FF00FF", displayName: "Fuchsia"),
        UnderlineColor(id: "pink4", name: "Blush", hex: "#DE5D83", displayName: "Blush"),
        UnderlineColor(id: "pink5", name: "Bubblegum", hex: "#FFC1CC", displayName: "Bubblegum"),
        UnderlineColor(id: "pink6", name: "Carnation", hex: "#FFA6C9", displayName: "Carnation"),
        UnderlineColor(id: "pink7", name: "Flamingo", hex: "#FC8EAC", displayName: "Flamingo"),
        UnderlineColor(id: "pink8", name: "Watermelon", hex: "#FE7F9C", displayName: "Watermelon"),
        UnderlineColor(id: "pink9", name: "Strawberry", hex: "#FC5A8D", displayName: "Strawberry"),
        UnderlineColor(id: "pink10", name: "Cherry", hex: "#FFB7C5", displayName: "Cherry Blossom"),

        // 棕色系 (10)
        UnderlineColor(id: "brown1", name: "Brown", hex: "#A2845E", displayName: "Brown"),
        UnderlineColor(id: "brown2", name: "Chocolate", hex: "#D2691E", displayName: "Chocolate"),
        UnderlineColor(id: "brown3", name: "Coffee", hex: "#6F4E37", displayName: "Coffee"),
        UnderlineColor(id: "brown4", name: "Mocha", hex: "#967969", displayName: "Mocha"),
        UnderlineColor(id: "brown5", name: "Tan", hex: "#D2B48C", displayName: "Tan"),
        UnderlineColor(id: "brown6", name: "Caramel", hex: "#C68E17", displayName: "Caramel"),
        UnderlineColor(id: "brown7", name: "Cinnamon", hex: "#D2691E", displayName: "Cinnamon"),
        UnderlineColor(id: "brown8", name: "Chestnut", hex: "#954535", displayName: "Chestnut"),
        UnderlineColor(id: "brown9", name: "Walnut", hex: "#773F1A", displayName: "Walnut"),
        UnderlineColor(id: "brown10", name: "Espresso", hex: "#4E2A2A", displayName: "Espresso"),

        // 灰色系 (10)
        UnderlineColor(id: "gray1", name: "Gray", hex: "#8E8E93", displayName: "Gray"),
        UnderlineColor(id: "gray2", name: "Silver", hex: "#C0C0C0", displayName: "Silver"),
        UnderlineColor(id: "gray3", name: "Charcoal", hex: "#36454F", displayName: "Charcoal"),
        UnderlineColor(id: "gray4", name: "Slate", hex: "#708090", displayName: "Slate"),
        UnderlineColor(id: "gray5", name: "Ash", hex: "#B2BEB5", displayName: "Ash"),
        UnderlineColor(id: "gray6", name: "Smoke", hex: "#738276", displayName: "Smoke"),
        UnderlineColor(id: "gray7", name: "Pewter", hex: "#899499", displayName: "Pewter"),
        UnderlineColor(id: "gray8", name: "Storm", hex: "#4F666A", displayName: "Storm"),
        UnderlineColor(id: "gray9", name: "Graphite", hex: "#383428", displayName: "Graphite"),
        UnderlineColor(id: "gray10", name: "Iron", hex: "#5A5E6B", displayName: "Iron"),
    ]

    /// 默认颜色（绿色）
    static let defaultColor = allColors.first(where: { $0.id == "green1" }) ?? allColors[0]
}

/// 颜色配置管理器
struct ColorConfig {
    /// 用户选择的下划线颜色
    static var underlineColor: UnderlineColor {
        get {
            // 从 UserDefaults 读取保存的颜色 ID
            if let savedColorId = UserDefaults.standard.string(forKey: "underlineColorId"),
               let color = UnderlineColors.allColors.first(where: { $0.id == savedColorId }) {
                return color
            }
            // 返回默认颜色
            return UnderlineColors.defaultColor
        }
        set {
            // 保存颜色 ID 到 UserDefaults
            UserDefaults.standard.set(newValue.id, forKey: "underlineColorId")
        }
    }
}

// MARK: - NSColor Extension

extension NSColor {
    /// 从十六进制字符串创建 NSColor
    /// - Parameter hex: 十六进制颜色码（支持 "#RRGGBB" 格式）
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

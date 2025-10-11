//
//  ColorSettingsView.swift
//  Spello
//
//  Created by eevv on 10/10/25.
//


import SwiftUI
import Ollama


/// 颜色选择按钮（紧凑版）
struct ColorButton: View {
    let color: UnderlineColor
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 3) {
                // 颜色圆形预览（缩小尺寸）
                Circle()
                    .fill(Color(nsColor: color.nsColor))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.blue : (isHovering ? Color.gray.opacity(0.5) : Color.clear),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isHovering ? .black.opacity(0.15) : .clear, radius: 2)

                // 颜色名称（极小字体）
                Text(color.name)
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.08) : (isHovering ? Color.gray.opacity(0.05) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .help(color.displayName)  // 添加工具提示显示完整名称
    }
}

/// 预览文本和下划线
struct PreviewTextWithUnderline: View {
    let text: String
    let color: NSColor

    var body: some View {
        VStack(spacing: 2) {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            // 下划线
            Rectangle()
                .fill(Color(nsColor: color))
                .frame(height: 1)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
    }
}

struct ColorSettingsView: View {
    @State private var selectedColor = ColorConfig.underlineColor

    var body: some View {
        Form {
            Section {
                Text("Choose the color for underlined text")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            // 预览区域（放在上面）
            Section("Preview") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Selected:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(selectedColor.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                    }

                    // 预览文本和下划线（只一行）
                    PreviewTextWithUnderline(
                        text: "The quick brown fox jumps over the lazy dog",
                        color: selectedColor.nsColor
                    )
                }
            }

            // 颜色选择区域（放在下面，使用滚动视图）
            Section("Available Colors") {
                // 颜色网格（10 列，更紧凑）
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 10), spacing: 8) {
                    ForEach(UnderlineColors.allColors) { color in
                        ColorButton(
                            color: color,
                            isSelected: selectedColor.id == color.id,
                            onSelect: {
                                selectedColor = color
                                ColorConfig.underlineColor = color
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Color")
    }
}

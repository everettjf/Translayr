//
//  FloatingSuggestionWindow.swift
//  Spello
//
//  浮动的拼写建议窗口
//

import SwiftUI
import AppKit

class FloatingSuggestionWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = true
        self.isReleasedWhenClosed = false

        // 设置内容视图
        self.contentView = NSHostingView(rootView: SuggestionWindowContent())
    }
}

struct SuggestionWindowContent: View {
    @EnvironmentObject var spellMonitor: SpellCheckMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let currentSuggestion = spellMonitor.currentSuggestion {
                // 标题
                HStack {
                    Text("拼写建议")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        spellMonitor.hideSuggestions()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor)

                // 错误词
                VStack(alignment: .leading, spacing: 4) {
                    Text("错误词: \(currentSuggestion.word)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !currentSuggestion.context.isEmpty {
                        Text("上下文: \(currentSuggestion.context)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // 建议列表
                ScrollView {
                    VStack(spacing: 2) {
                        if !currentSuggestion.candidates.isEmpty {
                            ForEach(currentSuggestion.candidates, id: \.self) { candidate in
                                Button(action: {
                                    spellMonitor.applySuggestion(candidate)
                                }) {
                                    HStack {
                                        Text(candidate)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .background(Color.white.opacity(0.001))
                                .onHover { isHovered in
                                    // TODO: 添加悬停效果
                                }
                            }
                        } else {
                            Text("没有建议")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }
                .frame(maxHeight: 120)

                Divider()

                // 操作按钮
                HStack {
                    Button("忽略") {
                        spellMonitor.ignoreSuggestion()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    if currentSuggestion.source == "AI Translation" {
                        Text("AI 翻译")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

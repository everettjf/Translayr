//
//  ContentView.swift
//  Spello
//
//  Created by eevv on 9/28/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var spellService = SpellService()
    @State private var text = """
    这是一个示例文本。你可以在这里输入或粘贴中文文本，应用会自动为你提供英文翻译建议。

    试试输入一些中文词汇，比如"人工智能"、"机器学习"、"深度学习"等，看看翻译效果。
    """
    @State private var isAutomaticSpellingCorrectionEnabled = true
    @State private var selectedLanguage: String? = nil
    @State private var showingSuggestions = false
    @State private var suggestions: [Suggestion] = []
    @State private var isCheckingSpelling = false

    private let availableLanguages = [
        "en_US": "English (US)",
        "en_GB": "English (UK)",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "pt": "Portuguese",
        "zh_Hans": "Chinese (Simplified)"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Check button
                Button(action: performSpellCheck) {
                    HStack {
                        if isCheckingSpelling {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "text.magnifyingglass")
                        }
                        Text("Check Spelling")
                    }
                }
                .disabled(isCheckingSpelling || text.isEmpty)
                .buttonStyle(.borderedProminent)

                Spacer()

                // Settings
                HStack(spacing: 16) {
                    // Auto-correction toggle
                    Toggle("Auto-correct", isOn: $isAutomaticSpellingCorrectionEnabled)
                        .toggleStyle(SwitchToggleStyle())

                    // Language selector
                    Picker("Language", selection: $selectedLanguage) {
                        Text("Auto-detect").tag(String?.none)
                        ForEach(Array(availableLanguages.keys.sorted()), id: \.self) { key in
                            Text(availableLanguages[key] ?? key).tag(String?.some(key))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Text editor
            SpellCheckedTextView(
                text: $text,
                isAutomaticSpellingCorrectionEnabled: $isAutomaticSpellingCorrectionEnabled,
                selectedLanguage: $selectedLanguage
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Status bar
            HStack {
                Text("Characters: \(text.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !suggestions.isEmpty {
                    Button("View \(suggestions.count) spelling issues") {
                        showingSuggestions = true
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSuggestions, onDismiss: {
            showingSuggestions = false
        }) {
            SuggestionsView(
                suggestions: $suggestions,
                text: $text,
                isPresented: $showingSuggestions,
                spellService: spellService
            )
        }
        .onAppear {
            // Set up initial spell checking
            NSSpellChecker.shared.automaticallyIdentifiesLanguages = true
        }
    }

    private func performSpellCheck() {
        guard !text.isEmpty else { return }

        isCheckingSpelling = true

        Task {
            // 先获取系统拼写检查结果
            let systemSuggestions = await Task.detached {
                self.spellService.scanSystem(text: self.text, language: self.selectedLanguage)
            }.value

            // 如果启用了 AI 翻译，获取翻译建议
            var modelSuggestions: [Suggestion] = []
            if spellService.isLocalModelEnabled {
                modelSuggestions = await spellService.analyzeWithLocalModelAsync(
                    text: text,
                    language: selectedLanguage
                )
            }

            // 合并建议
            let mergedSuggestions = spellService.merge(systemSuggestions, modelSuggestions)

            await MainActor.run {
                self.suggestions = mergedSuggestions
                self.isCheckingSpelling = false

                if !mergedSuggestions.isEmpty {
                    self.showingSuggestions = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

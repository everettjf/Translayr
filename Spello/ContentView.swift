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
    This is a sample text with some speling errors. You can type or paste your text here to check for mistakes. The app will highlight misspelled words and provide suggestions.

    Try typing some words with intentional errors like 'recieve', 'seperate', or 'definately' to see the spell checker in action.
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

                    // Local model toggle
                    Toggle("AI Suggestions", isOn: $spellService.isLocalModelEnabled)
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

        DispatchQueue.global(qos: .userInitiated).async {
            let foundSuggestions = spellService.checkFullText(text, language: selectedLanguage)

            DispatchQueue.main.async {
                self.suggestions = foundSuggestions
                self.isCheckingSpelling = false

                if !foundSuggestions.isEmpty {
                    self.showingSuggestions = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

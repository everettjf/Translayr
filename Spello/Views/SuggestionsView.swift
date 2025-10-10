//
//  SuggestionsView.swift
//  Spello
//
//  Created by XNU on 9/28/25.
//

import SwiftUI

struct SuggestionsView: View {
    @Binding var suggestions: [Suggestion]
    @Binding var text: String
    @Binding var isPresented: Bool
    @ObservedObject var spellService: SpellService

    var body: some View {
        VStack {
            HStack {
                Text("Spelling Issues (\(suggestions.count))")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    isPresented = false
                }
            }
            .padding()

            if suggestions.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("No spelling issues found!")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(suggestions) { suggestion in
                            SuggestionRowView(
                                suggestion: suggestion,
                                text: $text,
                                suggestions: $suggestions,
                                spellService: spellService
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct SuggestionRowView: View {
    let suggestion: Suggestion
    @Binding var text: String
    @Binding var suggestions: [Suggestion]
    @ObservedObject var spellService: SpellService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.word)
                    .font(.headline)
                    .foregroundColor(.red)

                Spacer()

                Text(suggestion.source)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(suggestion.source == "System" ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
                    .foregroundColor(suggestion.source == "System" ? .blue : .purple)
                    .cornerRadius(4)
            }

            Text("Context: \(suggestion.context)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if !suggestion.candidates.isEmpty {
                Text("Suggestions:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                    ForEach(suggestion.candidates.prefix(4), id: \.self) { candidate in
                        Button(candidate) {
                            applySuggestion(candidate)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.blue)
                    }
                }
            }

            HStack {
                Button("Ignore") {
                    ignoreWord()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.orange)

                Button("Add to Dictionary") {
                    addToDictionary()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.green)

                Spacer()
            }
            .font(.caption)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func applySuggestion(_ candidate: String) {
        var updatedText = text
        spellService.applyReplacement(text: &updatedText, for: suggestion, with: candidate)
        text = updatedText
        suggestions.removeAll { $0.id == suggestion.id }
    }

    private func ignoreWord() {
        spellService.ignore(word: suggestion.word)
        suggestions.removeAll { $0.id == suggestion.id }
    }

    private func addToDictionary() {
        spellService.addToUserDictionary(word: suggestion.word)
        suggestions.removeAll { $0.id == suggestion.id }
    }
}

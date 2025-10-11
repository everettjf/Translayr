//
//  LanguageSettingsView.swift
//  Spello
//
//  Created by eevv on 10/10/25.
//


import SwiftUI
import Ollama

struct LanguageSettingsView: View {
    @State private var selectedLanguage = LanguageConfig.sourceLanguage
    @State private var selectedTargetLanguage = LanguageConfig.targetLanguage

    var body: some View {
        Form {
            Section {
                Text("Select which language Spello should detect and translate")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Section("Source Language (Detect)") {
                Picker("Select language", selection: $selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.displayName)
                            .tag(language)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedLanguage) { _, newLanguage in
                    LanguageConfig.sourceLanguage = newLanguage
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.callout)

                    Text("Spello will detect \(selectedLanguage.displayName) text in other applications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section("Target Language (Translate to)") {
                Picker("Select target language", selection: $selectedTargetLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.displayName)
                            .tag(language)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedTargetLanguage) { _, newLanguage in
                    LanguageConfig.targetLanguage = newLanguage
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Same language warning - prominent display
                    if selectedLanguage == selectedTargetLanguage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Warning: Same Language Selected")
                                    .font(.callout.weight(.semibold))
                                    .foregroundColor(.red)

                                Text("Source and target languages are both \(selectedLanguage.displayName). Translation may not work as expected.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.callout)

                        Text("Detected text will be translated to \(selectedTargetLanguage.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.callout)

                        Text("Please ensure your selected AI model supports \(selectedLanguage.displayName) → \(selectedTargetLanguage.displayName) translation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Section("How It Works") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detection")
                                .font(.callout.weight(.semibold))
                            Text("Spello monitors text in other applications and detects \(selectedLanguage.displayName) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Translation")
                                .font(.callout.weight(.semibold))
                            Text("Detected text is translated to \(selectedTargetLanguage.displayName) using your selected AI model")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Underline & Click")
                                .font(.callout.weight(.semibold))
                            Text("Detected text is underlined. Click to see the translation in a popup")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Language")
    }
}
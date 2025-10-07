//
//  SpellCheckedTextView.swift
//  Spello
//
//  Created by eevv on 9/28/25.
//

import SwiftUI
import AppKit

struct SpellCheckedTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isAutomaticSpellingCorrectionEnabled: Bool
    @Binding var selectedLanguage: String?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = ChineseDetectingTextView()

        // Configure text view
        textView.isRichText = true  // Enable rich text for underline attributes
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.usesFontPanel = false
        textView.usesRuler = false

        // Fix layout issues
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        // Enable spell checking
        textView.isContinuousSpellCheckingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = isAutomaticSpellingCorrectionEnabled
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false

        // Set up delegate
        textView.delegate = context.coordinator

        // Configure scroll view properly
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder

        // Set initial text
        textView.string = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ChineseDetectingTextView else { return }

        // Update text if it changed externally
        if textView.string != text {
            textView.string = text
            // Trigger underline detection after setting text
            textView.detectAndUnderlineChineseText()
        }

        // Update spelling correction setting
        textView.isAutomaticSpellingCorrectionEnabled = isAutomaticSpellingCorrectionEnabled

        // Update language if specified
        if selectedLanguage != nil {
            let _ = NSSpellChecker.uniqueSpellDocumentTag()
            // Note: Language setting is handled automatically by the spell checker
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SpellCheckedTextView

        init(_ parent: SpellCheckedTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            DispatchQueue.main.async {
                self.parent.text = textView.string
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle special key commands if needed
            return false
        }

        // Context menu customization
        func textView(_ textView: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            // Get the range of the word at the click location
            let clickedRange = textView.selectionRange(for: charIndex)
            let clickedWord = (textView.string as NSString).substring(with: clickedRange)

            // Check if the word is misspelled
            let spellRange = NSSpellChecker.shared.checkSpelling(
                of: textView.string,
                startingAt: clickedRange.location,
                language: nil,
                wrap: false,
                inSpellDocumentWithTag: 0,
                wordCount: nil
            )

            if spellRange.location != NSNotFound && spellRange == clickedRange {
                // Add spelling suggestions to the menu
                let suggestions = NSSpellChecker.shared.guesses(
                    forWordRange: spellRange,
                    in: textView.string,
                    language: nil,
                    inSpellDocumentWithTag: 0
                ) ?? []

                if !suggestions.isEmpty {
                    // Add separator before spelling suggestions
                    menu.insertItem(NSMenuItem.separator(), at: 0)

                    // Add spelling suggestions
                    for (index, suggestion) in suggestions.enumerated() {
                        let menuItem = NSMenuItem(title: suggestion, action: #selector(replaceMisspelledWord(_:)), keyEquivalent: "")
                        menuItem.target = self
                        menuItem.representedObject = ["range": spellRange, "replacement": suggestion, "textView": textView]
                        menu.insertItem(menuItem, at: index)
                    }

                    // Add "Ignore Spelling" option
                    let ignoreItem = NSMenuItem(title: "Ignore Spelling", action: #selector(ignoreSpelling(_:)), keyEquivalent: "")
                    ignoreItem.target = self
                    ignoreItem.representedObject = ["word": clickedWord, "textView": textView]
                    menu.insertItem(ignoreItem, at: suggestions.count)

                    // Add "Learn Spelling" option
                    let learnItem = NSMenuItem(title: "Learn Spelling", action: #selector(learnSpelling(_:)), keyEquivalent: "")
                    learnItem.target = self
                    learnItem.representedObject = ["word": clickedWord]
                    menu.insertItem(learnItem, at: suggestions.count + 1)
                }
            }

            return menu
        }

        @objc private func replaceMisspelledWord(_ sender: NSMenuItem) {
            guard let info = sender.representedObject as? [String: Any],
                  let range = info["range"] as? NSRange,
                  let replacement = info["replacement"] as? String,
                  let textView = info["textView"] as? NSTextView else { return }

            textView.replaceCharacters(in: range, with: replacement)

            DispatchQueue.main.async {
                self.parent.text = textView.string
            }
        }

        @objc private func ignoreSpelling(_ sender: NSMenuItem) {
            guard let info = sender.representedObject as? [String: Any],
                  let word = info["word"] as? String,
                  let textView = info["textView"] as? NSTextView else { return }

            NSSpellChecker.shared.ignoreWord(word, inSpellDocumentWithTag: 0)
            textView.checkTextInDocument(nil)
        }

        @objc private func learnSpelling(_ sender: NSMenuItem) {
            guard let info = sender.representedObject as? [String: Any],
                  let word = info["word"] as? String else { return }

            NSSpellChecker.shared.learnWord(word)
        }
    }
}

extension NSTextView {
    func selectionRange(for charIndex: Int) -> NSRange {
        let string = self.string as NSString
        var range = NSRange(location: charIndex, length: 0)

        // Find word boundaries
        let characterSet = CharacterSet.alphanumerics
        var start = charIndex
        var end = charIndex

        // Find start of word
        while start > 0 {
            let char = string.character(at: start - 1)
            if !characterSet.contains(UnicodeScalar(char)!) {
                break
            }
            start -= 1
        }

        // Find end of word
        while end < string.length {
            let char = string.character(at: end)
            if !characterSet.contains(UnicodeScalar(char)!) {
                break
            }
            end += 1
        }

        range = NSRange(location: start, length: end - start)
        return range
    }
}

// MARK: - Custom NSTextView with Chinese Detection

class ChineseDetectingTextView: NSTextView {
    private var chineseRanges: [NSRange] = []
    private var clickedRange: NSRange?

    override func didChangeText() {
        super.didChangeText()
        detectAndUnderlineChineseText()
    }

    func detectAndUnderlineChineseText() {
        guard let textStorage = textStorage else { return }

        chineseRanges = []
        let text = string as NSString
        let fullRange = NSRange(location: 0, length: text.length)

        // Remove all existing underlines first
        textStorage.removeAttribute(.underlineStyle, range: fullRange)
        textStorage.removeAttribute(.underlineColor, range: fullRange)

        // Priority 1: Detect sentences
        let sentencePattern = "[\\p{Han}][^。！？\\n]*[。！？]"
        if let sentenceRegex = try? NSRegularExpression(pattern: sentencePattern, options: []) {
            let matches = sentenceRegex.matches(in: string, options: [], range: fullRange)
            chineseRanges.append(contentsOf: matches.map { $0.range })
        }

        // Priority 2: Detect individual words not in sentences
        let wordPattern = "[\\p{Han}]{2,}"
        if let wordRegex = try? NSRegularExpression(pattern: wordPattern, options: []) {
            let matches = wordRegex.matches(in: string, options: [], range: fullRange)

            for match in matches {
                let covered = chineseRanges.contains { NSIntersectionRange($0, match.range).length > 0 }
                if !covered {
                    chineseRanges.append(match.range)
                }
            }
        }

        // Apply red underlines to detected ranges
        for range in chineseRanges {
            textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            textStorage.addAttribute(.underlineColor, value: NSColor.red, range: range)
        }
    }

    // Handle clicks on underlined text
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let index = characterIndex(for: point)

        // Check if clicked on Chinese text
        clickedRange = nil
        for range in chineseRanges {
            if NSLocationInRange(index, range) {
                clickedRange = range
                showTranslationPopup(for: range, at: point)
                return
            }
        }

        super.mouseDown(with: event)
    }

    private func showTranslationPopup(for range: NSRange, at point: NSPoint) {
        let text = (string as NSString).substring(with: range)
        print("🖱️ Clicked Chinese text: \(text)")

        clickedRange = range

        // Translate and show in substitution panel
        Task { @MainActor in
            let item = DetectedTextItem(text: text, range: range, type: .sentence)
            let translations = await SpellCheckMonitor.shared.translateItem(item)

            if !translations.isEmpty {
                // Show substitution panel with translations
                showSubstitutionPanel(original: text, suggestions: translations)
            } else {
                print("⚠️ No translations found")
            }
        }
    }

    private func showSubstitutionPanel(original: String, suggestions: [String]) {
        // Use NSSpellChecker's substitution panel
        let panel = NSSpellChecker.shared.substitutionsPanel
        panel.makeKeyAndOrderFront(self)

        // Or show a simple context menu with translations
        let menu = NSMenu()
        menu.addItem(withTitle: "Translate '\(original)':", action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        for (index, translation) in suggestions.prefix(5).enumerated() {
            let item = menu.addItem(withTitle: translation, action: #selector(replaceWithTranslation(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.representedObject = translation
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Ignore", action: #selector(ignoreText), keyEquivalent: "")

        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: self)
    }

    @objc private func replaceWithTranslation(_ sender: NSMenuItem) {
        guard let range = clickedRange,
              let translation = sender.representedObject as? String else { return }

        print("✏️ Replacing with: \(translation)")
        replaceCharacters(in: range, with: translation)

        // Remove underline
        textStorage?.removeAttribute(.underlineStyle, range: NSRange(location: range.location, length: translation.count))
        textStorage?.removeAttribute(.underlineColor, range: NSRange(location: range.location, length: translation.count))
    }

    @objc private func ignoreText() {
        guard let range = clickedRange else { return }
        // Remove underline for this range
        textStorage?.removeAttribute(.underlineStyle, range: range)
        textStorage?.removeAttribute(.underlineColor, range: range)
    }
}
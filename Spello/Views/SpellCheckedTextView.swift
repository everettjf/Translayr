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

        // Enable context menu
        textView.autoresizingMask = [.width]

        print("✅ ChineseDetectingTextView configured")

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
            print("\n🚨 Delegate menu method CALLED!")
            print("   Character index: \(charIndex)")

            // Check if it's a ChineseDetectingTextView
            guard let chineseTextView = textView as? ChineseDetectingTextView else {
                return menu
            }

            // Check if clicked on Chinese text
            if let chineseMenu = chineseTextView.createMenuForChineseText(at: charIndex) {
                print("✅ Chinese text menu created!")
                return chineseMenu
            }

            print("⚪ Not Chinese text, showing default menu")

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
    private var translationCache: [String: [String]] = [:]

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

        print("📝 Detected \(chineseRanges.count) Chinese ranges")
    }

    // Public method to create menu for Chinese text at given character index
    func createMenuForChineseText(at charIndex: Int) -> NSMenu? {
        print("   Checking Chinese ranges at index: \(charIndex)")
        print("   Chinese ranges count: \(chineseRanges.count)")

        // Check if clicked on Chinese text
        for (i, range) in chineseRanges.enumerated() {
            print("   Range \(i): \(range)")
            if NSLocationInRange(charIndex, range) {
                let text = (string as NSString).substring(with: range)
                print("✅ HIT! Right-clicked Chinese: \(text)")

                // Show NSSpellChecker panels demo
                showSpellCheckerPanelsDemo(for: text, range: range)

                return createTranslationMenu(for: text, range: range)
            }
        }

        print("   ⚪ No Chinese range matched")
        return nil
    }

    // MARK: - NSSpellChecker Panels Demo

    private func showSpellCheckerPanelsDemo(for text: String, range: NSRange) {
        print("\n📋 NSSpellChecker Panels Demo")
        print("=====================================")

        let checker = NSSpellChecker.shared

        // 1. Spelling Panel
        print("\n1️⃣ Spelling Panel")
        let spellingPanel = checker.spellingPanel
        print("   Type: \(type(of: spellingPanel))")
        print("   Title: \(spellingPanel.title)")

        // Update spelling panel with the Chinese text
        checker.updateSpellingPanel(withMisspelledWord: text)
        spellingPanel.makeKeyAndOrderFront(self)
        print("   ✅ Spelling panel shown with word: \(text)")

        // 2. Substitutions Panel
        print("\n2️⃣ Substitutions Panel")
        let substitutionsPanel = checker.substitutionsPanel
        print("   Type: \(type(of: substitutionsPanel))")
        print("   Title: \(substitutionsPanel.title)")

        // Show substitutions panel
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            substitutionsPanel.makeKeyAndOrderFront(self)
            print("   ✅ Substitutions panel shown")
        }

        // 3. Update with Grammar String (for highlighting)
        print("\n3️⃣ Update Spelling Panel with Grammar Detail")
        let grammarDetail: [String: Any] = [
            NSGrammarRange: NSValue(range: range),
            NSGrammarUserDescription: "Chinese text detected: '\(text)'",
            NSGrammarCorrections: ["Translation 1", "Translation 2", "Translation 3"]
        ]
        checker.updateSpellingPanel(withGrammarString: string, detail: grammarDetail)
        print("   ✅ Updated with grammar detail")

        // 4. Add Accessory View to Spelling Panel
        print("\n4️⃣ Add Accessory View to Spelling Panel")
        if checker.accessoryView == nil {
            let accessoryView = createAccessoryView()
            checker.accessoryView = accessoryView
            print("   ✅ Accessory view added to spelling panel")
        } else {
            print("   ℹ️ Accessory view already exists")
        }

        // 5. Add Accessory ViewController to Substitutions Panel
        print("\n5️⃣ Add Accessory ViewController to Substitutions Panel")
        if checker.substitutionsPanelAccessoryViewController == nil {
            let accessoryVC = createAccessoryViewController()
            checker.substitutionsPanelAccessoryViewController = accessoryVC
            print("   ✅ Accessory view controller added to substitutions panel")
        } else {
            print("   ℹ️ Accessory view controller already exists")
        }

        // 6. Update Panels
        print("\n6️⃣ Update Panels")
        checker.updatePanels()
        print("   ✅ Panels updated")

        print("\n=====================================\n")
    }

    private func createAccessoryView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor

        let label = NSTextField(labelWithString: "🎯 Custom Accessory View")
        label.frame = NSRect(x: 10, y: 30, width: 280, height: 20)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        view.addSubview(label)

        let button = NSButton(title: "Test Button", target: nil, action: nil)
        button.frame = NSRect(x: 10, y: 5, width: 100, height: 20)
        view.addSubview(button)

        return view
    }

    private func createAccessoryViewController() -> NSViewController {
        let viewController = NSViewController()

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.1).cgColor

        let label = NSTextField(labelWithString: "🚀 Substitutions Panel Accessory")
        label.frame = NSRect(x: 10, y: 50, width: 280, height: 20)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        view.addSubview(label)

        let infoLabel = NSTextField(labelWithString: "This is a custom accessory view controller")
        infoLabel.frame = NSRect(x: 10, y: 30, width: 280, height: 15)
        infoLabel.font = NSFont.systemFont(ofSize: 11)
        infoLabel.textColor = .secondaryLabelColor
        view.addSubview(infoLabel)

        let slider = NSSlider(value: 0.5, minValue: 0, maxValue: 1, target: nil, action: nil)
        slider.frame = NSRect(x: 10, y: 5, width: 280, height: 20)
        view.addSubview(slider)

        viewController.view = view
        return viewController
    }

    private func createTranslationMenu(for text: String, range: NSRange) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Translate '\(text)'...", action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        // Add "Translate" option that triggers async translation
        let translateItem = menu.addItem(withTitle: "Get Translation", action: #selector(translateNow(_:)), keyEquivalent: "")
        translateItem.representedObject = ["text": text, "range": NSValue(range: range)]

        menu.addItem(NSMenuItem.separator())
        let ignoreItem = menu.addItem(withTitle: "Ignore", action: #selector(ignoreUnderline(_:)), keyEquivalent: "")
        ignoreItem.representedObject = NSValue(range: range)

        return menu
    }

    @objc private func translateNow(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? [String: Any],
              let text = info["text"] as? String,
              let rangeValue = info["range"] as? NSValue else { return }

        let range = rangeValue.rangeValue

        print("🔄 Translating: \(text)")

        // Show translations
        Task { @MainActor in
            let item = DetectedTextItem(text: text, range: range, type: .sentence)
            let translations = await SpellCheckMonitor.shared.translateItem(item)

            if !translations.isEmpty {
                self.showTranslationSelectionMenu(original: text, translations: translations, range: range)
            }
        }
    }

    private func showTranslationSelectionMenu(original: String, translations: [String], range: NSRange) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Select translation:", action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        for translation in translations.prefix(5) {
            let item = menu.addItem(withTitle: translation, action: #selector(replaceWithTranslation(_:)), keyEquivalent: "")
            item.representedObject = ["translation": translation, "range": NSValue(range: range)]
        }

        // Show menu at mouse location
        if let event = NSApp.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }

    @objc private func replaceWithTranslation(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? [String: Any],
              let translation = info["translation"] as? String,
              let rangeValue = info["range"] as? NSValue else { return }

        let range = rangeValue.rangeValue

        print("✏️ Replacing with: \(translation)")
        replaceCharacters(in: range, with: translation)
    }

    @objc private func ignoreUnderline(_ sender: NSMenuItem) {
        guard let rangeValue = sender.representedObject as? NSValue else { return }
        let range = rangeValue.rangeValue

        textStorage?.removeAttribute(.underlineStyle, range: range)
        textStorage?.removeAttribute(.underlineColor, range: range)
    }
}
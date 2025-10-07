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

        // Context menu customization - only for substitutions
        func textView(_ textView: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            // Keep default menu for substitutions panel
            return menu
        }

        // Handle link clicks in the text view
        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            print("\n🔗 Link clicked!")
            print("   Link: \(link)")
            print("   Character index: \(charIndex)")

            guard let chineseTextView = textView as? ChineseDetectingTextView else { return false }

            // Find which range contains this character
            for range in chineseTextView.chineseRanges {
                if NSLocationInRange(charIndex, range) {
                    let text = (textView.string as NSString).substring(with: range)
                    print("✅ Found Chinese text: \(text)")

                    // Show floating window with translations
                    chineseTextView.showTranslationWindow(for: text, range: range, at: charIndex)
                    return true
                }
            }

            return false
        }
    }
}

// MARK: - Custom NSTextView with Chinese Detection

class ChineseDetectingTextView: NSTextView {
    var chineseRanges: [NSRange] = []
    private var translationCache: [String: [String]] = [:]
    private var currentPopover: NSPopover?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

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

        // Apply red underlines and link attributes to detected ranges
        for range in chineseRanges {
            let text = (string as NSString).substring(with: range)

            // Add red underline
            textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            textStorage.addAttribute(.underlineColor, value: NSColor.red, range: range)

            // Add link attribute to make it clickable
            textStorage.addAttribute(.link, value: "chinese://\(text)", range: range)

            // Set cursor to pointer when hovering
            textStorage.addAttribute(.cursor, value: NSCursor.pointingHand, range: range)
        }

        print("📝 Detected \(chineseRanges.count) Chinese ranges")
    }

    // Show translation window at clicked text
    func showTranslationWindow(for text: String, range: NSRange, at charIndex: Int) {
        print("🪟 Showing translation window for: \(text)")

        // Close existing popover if any
        currentPopover?.close()

        // Get the rect for the clicked range
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else { return }

        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        // Convert to view coordinates
        let rect = NSRect(
            x: boundingRect.origin.x + textContainerInset.width,
            y: boundingRect.origin.y + textContainerInset.height,
            width: boundingRect.width,
            height: boundingRect.height
        )

        // Create popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.animates = true

        // Create SwiftUI view for popover content
        let contentView = TranslationPopoverView(
            text: text,
            range: range,
            onSelect: { [weak self] translation in
                self?.replaceCharacters(in: range, with: translation)
                popover.close()
            },
            onIgnore: { [weak self] in
                self?.removeUnderline(for: range)
                popover.close()
            }
        )

        popover.contentViewController = NSHostingController(rootView: contentView)
        currentPopover = popover

        // Show popover relative to the text
        popover.show(relativeTo: rect, of: self, preferredEdge: .maxY)
    }

    private func removeUnderline(for range: NSRange) {
        textStorage?.removeAttribute(.underlineStyle, range: range)
        textStorage?.removeAttribute(.underlineColor, range: range)
        textStorage?.removeAttribute(.link, range: range)
        textStorage?.removeAttribute(.cursor, range: range)
    }

    // MARK: - Translation Menu

    func createTranslationMenu(for text: String, range: NSRange) -> NSMenu {
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

// MARK: - Translation Popover View

struct TranslationPopoverView: View {
    let text: String
    let range: NSRange
    let onSelect: (String) -> Void
    let onIgnore: () -> Void

    @State private var translations: [String] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Translate")
                    .font(.headline)
                Spacer()
                Button(action: onIgnore) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)

            // Original text
            VStack(alignment: .leading, spacing: 4) {
                Text("Original")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.body)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }

            Divider()

            // Translations
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Translating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if translations.isEmpty {
                Text("No translations available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(translations.prefix(5), id: \.self) { translation in
                                Button(action: {
                                    onSelect(translation)
                                }) {
                                    HStack {
                                        Text(translation)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "arrow.right.circle")
                                            .foregroundColor(.accentColor)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }

            // Ignore button
            Button(action: onIgnore) {
                HStack {
                    Image(systemName: "eye.slash")
                    Text("Ignore")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 300)
        .task {
            await loadTranslations()
        }
    }

    private func loadTranslations() async {
        isLoading = true
        let item = DetectedTextItem(text: text, range: range, type: .sentence)
        let results = await SpellCheckMonitor.shared.translateItem(item)
        translations = results
        isLoading = false
    }
}
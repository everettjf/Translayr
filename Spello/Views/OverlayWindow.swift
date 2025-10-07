//
//  OverlayWindow.swift
//  Spello
//
//  Transparent overlay window for displaying underlines over other apps
//

import Cocoa
import SwiftUI

/// Transparent window that floats above all other apps to show underlines
class OverlayWindow: NSWindow {

    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Make window transparent
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false

        // Set window level to float above other apps
        self.level = .floating

        // Make window appear on all spaces and above fullscreen apps
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Don't show in window switcher
        self.isMovableByWindowBackground = false

        // Allow mouse events to pass through except on underlines
        self.ignoresMouseEvents = false
    }

    /// Update window position and show underline
    func showUnderline(at rect: NSRect, text: String) {
        // Position window at the text location
        self.setFrame(rect, display: true)

        // Create underline view
        let underlineView = UnderlineView(frame: NSRect(x: 0, y: 0, width: rect.width, height: rect.height))
        underlineView.text = text
        self.contentView = underlineView

        self.orderFrontRegardless()
    }

    func hide() {
        self.orderOut(nil)
    }
}

/// Custom view that draws red underline and handles clicks
class UnderlineView: NSView {
    var text: String = ""
    var onClicked: ((String) -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw red underline at the bottom
        NSColor.red.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 2))
        path.line(to: NSPoint(x: bounds.width, y: 2))
        path.lineWidth = 2
        path.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        // Handle click - show translation popup
        print("🖱️ Clicked on underlined text: \(text)")
        onClicked?(text)
    }

    // Accept first mouse to allow clicking without activating window
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

/// Manager for overlay windows
@MainActor
class OverlayWindowManager {
    static let shared = OverlayWindowManager()

    private var overlayWindows: [String: OverlayWindow] = [:]

    private init() {}

    /// Show underline for a detected text item
    func showUnderline(for item: DetectedTextItem, at bounds: NSRect, element: AXUIElement) {
        let key = "\(item.range.location)-\(item.range.length)"

        // Convert accessibility coordinates to screen coordinates
        // Accessibility uses top-left origin, need to flip Y
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let flippedY = screenHeight - bounds.origin.y - bounds.size.height
        let screenBounds = NSRect(
            x: bounds.origin.x,
            y: flippedY,
            width: bounds.size.width,
            height: bounds.size.height
        )

        // Create or update overlay window
        if let window = overlayWindows[key] {
            window.showUnderline(at: screenBounds, text: item.text)
        } else {
            let window = OverlayWindow(frame: screenBounds)
            window.showUnderline(at: screenBounds, text: item.text)

            // Set click handler
            if let underlineView = window.contentView as? UnderlineView {
                underlineView.onClicked = { [weak self] text in
                    Task { @MainActor in
                        await self?.handleTextClicked(text, item: item)
                    }
                }
            }

            overlayWindows[key] = window
        }
    }

    /// Hide all overlay windows
    func hideAll() {
        for window in overlayWindows.values {
            window.hide()
        }
        overlayWindows.removeAll()
    }

    /// Handle clicking on underlined text
    private func handleTextClicked(_ text: String, item: DetectedTextItem) async {
        print("🔄 Getting translations for: \(text)")

        // Get translations from SpellCheckMonitor
        let translations = await SpellCheckMonitor.shared.translateItem(item)

        // Show translation popup
        showTranslationPopup(for: text, translations: translations)
    }

    private func showTranslationPopup(for text: String, translations: [String]) {
        // Create a small popup window with translations
        let popupWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        popupWindow.title = "Translation: \(text)"
        popupWindow.level = .floating

        // Create SwiftUI view for translations
        let translationsView = TranslationPopupView(
            originalText: text,
            translations: translations,
            onSelect: { [weak popupWindow] translation in
                print("✅ Selected translation: \(translation)")
                // TODO: Replace text in the original app
                popupWindow?.close()
            }
        )

        popupWindow.contentView = NSHostingView(rootView: translationsView)
        popupWindow.center()
        popupWindow.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Translation Popup View

struct TranslationPopupView: View {
    let originalText: String
    let translations: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Translation")
                .font(.headline)

            Divider()

            if translations.isEmpty {
                Text("No translations available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(translations, id: \.self) { translation in
                            Button(action: {
                                onSelect(translation)
                            }) {
                                HStack {
                                    Text(translation)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle")
                                }
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

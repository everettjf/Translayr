# Translayr Technical Documentation

<p align="center">
  <a href="https://discord.com/invite/eGzEaP6TzR"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" /></a>
</p>

## Project Overview

Translayr is a macOS app that monitors Chinese text in other applications in real time and provides AI-powered translations. Users can type Chinese in any app; Translayr automatically detects it, displays a red underline beneath the text, and shows English translation suggestions on click.

## Core Features

1. **System-wide text monitoring** - Uses the macOS Accessibility API to monitor text input in other apps
2. **Chinese text detection** - Automatically identifies Chinese sentences and phrases
3. **Floating underline overlay** - Draws an overlay on top of other apps to mark detected text
4. **AI translation** - Uses local Ollama models for translation suggestions
5. **Window tracking** - Underlines follow as windows move or resize

## Core Architecture

### Three-Layer Design

```
┌─────────────────────────────────────────┐
│         SpellCheckMonitor               │  ← Core coordinator
│  - Subscribe to text changes            │
│  - Detect Chinese content               │
│  - Coordinate overlay display           │
└────────────┬────────────────────────────┘
             │
             ├──────────────┬──────────────┐
             ▼              ▼              ▼
┌────────────────┐  ┌──────────────┐  ┌──────────────┐
│ Accessibility  │  │  Overlay     │  │  Spell       │
│ Monitor        │  │  Window      │  │  Service     │
│                │  │  Manager     │  │              │
│ - Monitor text │  │ - Show lines │  │ - AI translate
│ - Get bounds   │  │ - Handle taps│  │ - Local model
│ - Track window │  │ - Coordinate │  │              │
└────────────────┘  └──────────────┘  └──────────────┘
```

### Core Components

#### 1. AccessibilityMonitor

**Responsibilities:**
- Monitor text input in the active app
- Get on-screen text bounds
- Track window movement and resize events

**Key APIs:**
```swift
// Read focused element text
var focusedElement: AXUIElement?
AXUIElementCopyAttributeValue(element, kAXValueAttribute, &value)

// Get on-screen bounds for a text range
AXUIElementCopyParameterizedAttributeValue(
    element,
    kAXBoundsForRangeParameterizedAttribute,
    rangeValue,
    &boundsValue
)

// Listen for window movement
AXObserverAddNotification(observer, window, kAXMovedNotification, nil)
```

**Dual position update strategy:**
1. **Primary:** Accessibility notifications (`kAXMovedNotification`, `kAXResizedNotification`)
2. **Fallback:** Timer polling (every 0.1s) to avoid missed notifications

#### 2. SpellCheckMonitor

**Responsibilities:**
- Central coordinator
- Subscribes to text and position changes using Combine
- Detects Chinese sentences and phrases
- Triggers overlay display and updates

**Chinese detection strategy:**
```swift
// Priority 1: Sentences (with punctuation)
let sentencePattern = "[\\p{Han}][^。！？；，、.!?,;（）()【】\\[\\]「」『』{}\\n]*[。！？；，、.!?,;（）()【】\\[\\]「」『』{}]"

// Priority 2: Independent phrases (2+ chars, non-overlapping)
let wordPattern = "[\\p{Han}]{2,}"
```

**Combine flow:**
```swift
// Text change listener with 500ms debounce
accessibilityMonitor.$currentText
    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
    .sink { [weak self] text in
        self?.detectChineseText(text)
    }

// Position change listener with 50ms debounce
accessibilityMonitor.$windowPositionChanged
    .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
    .sink { [weak self] _ in
        self?.updateOverlayPositions()
    }
```

#### 3. OverlayWindow

**Responsibilities:**
- Create transparent floating windows
- Render underlines above other apps
- Handle clicks and show translation popups

**Key design choices:**
```swift
// Window configuration
self.level = .floating
self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
self.ignoresMouseEvents = false
self.canBecomeKey = false
self.canBecomeMain = false

// Make entire text bounds clickable
let clickableRect = NSRect(
    x: rect.origin.x,
    y: rect.origin.y,
    width: rect.width,
    height: rect.height
)
```

**Coordinate conversion:**
```swift
// Accessibility uses top-left origin
// Cocoa uses bottom-left origin
let cocoaY = screenHeight - bounds.origin.y - bounds.size.height
```

**UX optimizations:**
- Hover state: blue translucent highlight + hand cursor
- Click area: full text bounds, not just underline
- Real-time feedback on hover/click

#### 4. SpellService + LocalModelClient

**Responsibilities:**
- Communicate with local Ollama models
- Translate Chinese to English
- Manage translation caching

**Ollama integration:**
```swift
let ollamaClient = Ollama.Client(host: hostURL)
let stream = ollamaClient.generateStream(
    model: modelID,
    prompt: prompt,
    options: [
        "temperature": .double(0.3),
        "top_p": .double(0.9),
        "top_k": .int(40)
    ]
)
```

**Config (OllamaConfig.swift):**
- Default model: `qwen2.5:3b`
- Temperature: 0.3 (lower for accuracy)
- Streaming response enabled

## Workflows

### 1. Startup Flow

```
Launch Translayr
    ↓
Check Accessibility permission
    ↓
Start AccessibilityMonitor
    ↓
Start SpellCheckMonitor
    ↓
Begin system-wide monitoring
```

### 2. Text Detection Flow

```
User types in another app
    ↓
AccessibilityMonitor checks focused element every 0.5s
    ↓
Text change publishes currentText
    ↓
SpellCheckMonitor debounces (500ms)
    ↓
Regex detects Chinese sentences/phrases
    ↓
Get screen bounds for each text segment
    ↓
OverlayWindowManager shows underlines
```

### 3. Window Movement Flow

```
User moves another app window
    ↓
Option 1: Accessibility sends kAXMovedNotification
    ↓
AccessibilityMonitor receives notification
    ↓
Toggle windowPositionChanged flag
    ↓
SpellCheckMonitor debounces (50ms)
    ↓
Recalculate all text bounds
    ↓
Update overlay positions
```

```
Option 2: Timer fallback (every 0.1s)
    ↓
checkWindowPosition() detects changes
    ↓
Trigger windowPositionChanged
    ↓
(Then same as above)
```

### 4. Translation Flow

```
User clicks underline
    ↓
UnderlineView.mouseDown
    ↓
onClicked callback
    ↓
OverlayWindowManager.handleTextClicked
    ↓
SpellCheckMonitor.translateItem
    ↓
SpellService.analyzeWithLocalModelAsync
    ↓
LocalModelClient.translateChineseToEnglish
    ↓
Ollama generates translation
    ↓
Show translation popup
    ↓
User selects translation -> replace original text
```

## Technical Highlights

### 1. Non-Intrusive Monitoring

Uses macOS Accessibility APIs without modifying other apps:

```swift
let activeApp = NSWorkspace.shared.frontmostApplication
let appElement = AXUIElementCreateApplication(pid)

var focusedElement: AnyObject?
AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute, &focusedElement)

var value: AnyObject?
AXUIElementCopyAttributeValue(element, kAXValueAttribute, &value)
```

### 2. Reactive Architecture

Combine provides a clear data flow:

```swift
@Published var currentText: String = ""
@Published var windowPositionChanged: Bool = false

accessibilityMonitor.$currentText
    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
    .sink { text in ... }
```

### 3. Accurate Position Tracking

**Coordinate systems:**
- Accessibility API: top-left origin (0,0), Y increases downward
- Cocoa: bottom-left origin (0,0), Y increases upward

**Conversion:**
```swift
cocoaY = screenHeight - accessibilityY - height
```

### 4. Performance Optimizations

**Debouncing:**
- Text detection: 500ms
- Position updates: 50ms

**Window reuse:**
```swift
let key = "\(range.location)-\(range.length)"
if let window = overlayWindows[key] {
    window.showUnderline(...)
} else {
    let window = OverlayWindow(...)
    overlayWindows[key] = window
}
```

## Key Files

| File | Responsibility | Importance |
|------|------|--------|
| **AccessibilityMonitor.swift** | Monitor text, bounds, window tracking | ⭐⭐⭐⭐⭐ |
| **SpellCheckMonitor.swift** | Coordinator, detection, updates | ⭐⭐⭐⭐⭐ |
| **OverlayWindow.swift** | Underline UI + click handling | ⭐⭐⭐⭐⭐ |
| **SpellService.swift** | Translation service | ⭐⭐⭐⭐ |
| **LocalModelClient.swift** | Ollama integration | ⭐⭐⭐⭐ |
| **OllamaConfig.swift** | Model configuration | ⭐⭐⭐ |
| **ContentView.swift** | Main UI view | ⭐⭐⭐ |
| **SpellCheckedTextView.swift** | In-app text editor | ⭐⭐ |
| **SystemServiceProvider.swift** | System service registration | ⭐⭐ |
| **Suggestion.swift** | Data model | ⭐ |

## Dependencies

- **macOS 13.0+** - modern Accessibility APIs
- **Ollama** - local AI runtime
- **Ollama Swift SDK** - client library
- **Combine** - reactive programming
- **SwiftUI** - UI framework

## Permissions

1. **Accessibility permission** - required to monitor other apps
   - Path: System Settings → Privacy & Security → Accessibility
   - Purpose: read text and bounds from other apps

2. **Ollama service** - must be running locally
   ```bash
   brew install ollama
   ollama serve
   ollama pull qwen2.5:3b
   ```

## FAQ

### Q1: Why is the underline misaligned?

Possible causes:
1. The app doesn’t support `kAXBoundsForRangeParameterizedAttribute`
2. Coordinate conversion issues
3. Window scaling or multi-display setup

Solution: check log coordinates and verify conversion math.

### Q2: Why do some apps not work?

Some apps may:
1. Use custom text rendering
2. Have incomplete Accessibility support
3. Restrict access with extra permissions

### Q3: How can I speed up translation?

1. Use a smaller model (e.g., `gemma2:2b`)
2. Lower temperature to reduce output length
3. Enable streaming for faster feedback

## Future Improvements

1. **Caching** - reuse translations for common phrases
2. **More languages** - add pairs like Japanese and Korean
3. **Custom models** - allow user-selectable translation models
4. **Offline dictionary** - fast lookups
5. **Translation history** - searchable history

## License

MIT License

---

**Last updated:** 2025-10-08
**Version:** 1.0.0
**Author:** eevv

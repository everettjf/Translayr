# Translayr - Agent Guide

<p align="center">
  <a href="https://discord.com/invite/eGzEaP6TzR"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" /></a>
</p>

## Project Focus

Translayr is a macOS **system-wide intelligent translation assistant**. It monitors text input across apps via Accessibility APIs and provides instant translation and one-click replacement using local AI models (Ollama).

## Core Capabilities

- **Cross-app monitoring**: Real-time input capture + language detection
- **Local translation**: Offline Ollama inference for privacy
- **Floating UI**: Underline markers + translation popups
- **Configurable**: Languages, colors, models, skip list

## Architecture Overview

```
AccessibilityMonitor -> SpellCheckMonitor -> SpellService -> LocalModelClient
                             │                    │
                             └── OverlayWindow <--┘
```

## Key Directories

- `Translayr/Models/`: Suggestion and related models
- `Translayr/Protocols/`: SpellAnalyzing protocol
- `Translayr/Services/`: Monitoring, spell check, translation, updates
- `Translayr/Views/`: OverlayWindow, MenuBarView, Settings
- `TranslayrTests/`: Unit tests
- `scripts/`: Release build, signing, notarization

## Key Files

- `Translayr/Services/AccessibilityMonitor.swift`
- `Translayr/Services/SpellCheckMonitor.swift`
- `Translayr/Services/SpellService.swift`
- `Translayr/Services/LocalModelClient.swift`
- `Translayr/Views/OverlayWindow.swift`
- `Translayr/Views/MenuBarView.swift`

## Dev Environment

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+
- Ollama (local)

## Common Commands

```bash
# Run
open Translayr.xcodeproj

# Debug build
xcodebuild -scheme Translayr -configuration Debug

# Version bump
./scripts/increment-version.sh
./scripts/increment-build.sh

# Release build (sign + notarize)
./scripts/build-release.sh
```

## Tests

- `TranslayrTests/SpellServiceTests.swift`
- `TranslayrTests/SuggestionTests.swift`
- `TranslayrTests/LocalModelClientTests.swift`

Run tests in Xcode: `⌘ + U`.

## Config Notes

- Ollama default endpoint: `http://127.0.0.1:11434`
- Model example: `qwen2.5:3b`
- Settings are stored in `UserDefaults`

## Known Limitations

- Accessibility permission required to read other apps.
- Some apps (e.g., certain Electron apps) may not expose precise text positions.
- Password fields are not accessible by design.

## Related Docs

- `DOCUMENT.md`
- `USAGE.md`
- `SYSTEM_SERVICE.md`
- `BUILD_RELEASE.md`
- `QUICK_START.md`

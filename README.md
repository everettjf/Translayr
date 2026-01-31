<h1 align="center">Translayr</h1>
<p align="center">System-wide AI translation for macOS</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" />
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" />
  <img src="https://img.shields.io/badge/Xcode-15.0+-blue.svg" />
  <img src="https://img.shields.io/badge/Ollama-Local%20AI-green.svg" />
  <a href="https://discord.com/invite/eGzEaP6TzR"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" /></a>
</p>

<p align="center">
  <a href="https://www.translayr.com">🌐 Website</a>
</p>

Translayr is a **system-wide intelligent translation assistant** for macOS. It monitors text input in any application, detects language automatically, and provides instant translations. By combining the macOS Accessibility API with local AI models (Ollama), Translayr delivers powerful, private, and seamless cross-app translation.

## Table of Contents

- [Key Features](#-key-features)
- [Download](#-download)
- [Quick Start](#-quick-start)
- [Usage Guide](#-usage-guide)
- [How It Works](#-how-it-works)
- [Project Structure](#-project-structure)
- [Development & Release](#-development--release)
- [Troubleshooting](#-troubleshooting)
- [Roadmap](#-roadmap)
- [Contributing & Community](#-contributing--community)
- [License](#-license)
- [Star History](#-star-history)

## ✨ Key Features

### 🌐 System-Wide Monitoring
- **Cross-app monitoring**: Detect and translate text in any macOS app (Notes, TextEdit, Safari, Chrome, etc.)
- **Real-time detection**: Automatic input field detection without manual triggers
- **Intelligent text analysis**: Tokenizes and recognizes phrases/sentences
- **App allow/skip list**: Exclude apps that should not be monitored

### 🤖 Smart Translation
- **Multilingual support**: Top 10 most-used languages worldwide
  - Chinese, English, Spanish, Hindi, Arabic, French, Bengali, Russian, Portuguese, Indonesian
- **Local AI models**: High-quality translation with Ollama, no internet required
- **Bidirectional translation**: Customizable source and target languages
- **Context-aware**: Uses full sentences for more accurate translation

### 🎨 Polished UI
- **Floating underline**: Colored underline for detected text
- **Hover highlight**: Visual feedback on hover
- **Popup translation**: Click underline to show translation popup
- **One-click replace**: Insert translation directly in the original app
- **Smart positioning**: Popup avoids covering text
- **Auto-hide**: Hides underline during scrolling, window movement, or space switching

### 🔒 Privacy First
- **Fully local processing**: Data never leaves your device
- **Offline by design**: No cloud services required
- **Permission-controlled**: Users control Accessibility permissions

### ⚙️ Configurable
- **Language selection**: Customize detection and target languages
- **Color themes**: Underline color options
- **App filtering**: Skip list for apps
- **Model selection**: Choose Ollama models
- **Menu bar integration**: Quick access from menu bar
- **Auto-update checks**: GitHub Releases-based update notifications

## 📥 Download

**Requirements:** macOS 15.0+ • [Ollama](https://ollama.ai)

1. Download the latest `.dmg`
2. Open it and drag Translayr to Applications
3. Launch and grant Accessibility permission

## 🚀 Quick Start

### 1. Install Ollama & Model

```bash
brew install ollama
ollama pull qwen2.5:3b
ollama serve
```

### 2. Install Translayr

1. Download and open the `.dmg` file
2. Drag Translayr to Applications
3. Launch and grant Accessibility permission

### 3. Start Using

Type in any app → Click underlined text → Translate instantly

---

## 📖 Usage Guide

### Supported Languages

| Language | Code | Minimum Length | Unicode Pattern |
|------|------|------------|-------------|
| Chinese | zh | 2 chars | CJK Unified Ideographs |
| English | en | 4 letters | Latin |
| Spanish | es | 3 letters | Latin + accents |
| Hindi | hi | 2 chars | Devanagari |
| Arabic | ar | 3 chars | Arabic |
| French | fr | 3 letters | Latin + accents |
| Bengali | bn | 2 chars | Bengali |
| Russian | ru | 3 letters | Cyrillic |
| Portuguese | pt | 3 letters | Latin + accents |
| Indonesian | id | 4 letters | Latin |

### Advanced Settings

#### Skip App List

In the "Skip Apps" setting, add apps you don’t want to monitor:

```
Xcode, Terminal, iTerm, 1Password
```

Comma-separated, case-insensitive.

#### Underline Colors

Select preferred underline color in "Colors":
- Red (default)
- Blue
- Green
- Purple
- Orange

#### Model Selection

Enter a model name in "Models" and save:

```
qwen2.5:3b
```

## 🔍 How It Works

```
User types in any app
          ↓
AccessibilityMonitor observes text changes
          ↓
SpellCheckMonitor detects target language
          ↓
OverlayWindow draws underline
          ↓
User clicks underline
          ↓
LocalModelClient calls Ollama
          ↓
Translation popup appears
          ↓
User selects translation
          ↓
Text replaced in original app
```

## 🏗️ Project Structure

```
Translayr/
├── Translayr/
│   ├── TranslayrApp.swift              # App entry, menu bar integration
│   ├── ContentView.swift               # Main view
│   │
│   ├── Models/
│   │   └── Suggestion.swift            # Suggestion model
│   │
│   ├── Protocols/
│   │   └── SpellAnalyzing.swift        # Spell analysis protocol
│   │
│   ├── Services/
│   │   ├── AccessibilityMonitor.swift  # Accessibility monitor
│   │   ├── SpellCheckMonitor.swift     # Spell check coordinator
│   │   ├── SpellService.swift          # Spell/translation logic
│   │   ├── LocalModelClient.swift      # Ollama client
│   │   ├── SystemServiceProvider.swift # System service provider
│   │   ├── LanguageConfig.swift        # Language configuration
│   │   └── UpdateChecker.swift         # Release update checker
│   │
│   ├── Views/
│   │   ├── OverlayWindow.swift         # Floating underline window
│   │   ├── MenuBarView.swift           # Menu bar view
│   │   └── SettingsView/
│   │       ├── SettingsView.swift
│   │       ├── GeneralSettingsView.swift
│   │       ├── LanguageSettingsView.swift
│   │       ├── ColorSettingsView.swift
│   │       ├── SkipAppsSettingsView.swift
│   │       ├── ModelsSettingsView.swift
│   │       ├── PreferencesSection.swift
│   │       └── AboutView.swift
│   │
│   └── Info.plist                       # App configuration
│
├── TranslayrTests/                      # Unit tests
├── scripts/
│   ├── build-release.sh                 # Release build script
│   ├── increment-build.sh               # Build number bump
│   ├── increment-version.sh             # Version bump
│   │
│   └── sign-and-notarize.sh             # Signing + notarization
├── README.md                            # Project overview
├── DOCUMENT.md                          # Technical documentation
├── USAGE.md                             # Usage manual
├── SYSTEM_SERVICE.md                    # System service integration
├── BUILD_RELEASE.md                     # Release build details
├── QUICK_START.md                       # 5-minute quick start
└── AGENTS.md                            # Agent guide
```

## 🔨 Development & Release

### Local Development

```bash
# Run with Xcode
open Translayr.xcodeproj
# Press ⌘ + R

# Or build from CLI
xcodebuild -scheme Translayr -configuration Debug
```

### Release Build

Automated scripts support signing and Apple notarization:

```bash
# 1. Bump version (optional)
./scripts/increment-version.sh  # 1.0.0 → 1.0.1
./scripts/increment-build.sh    # Build: 1 → 2

# 2. Build release (reads version from Info.plist)
./scripts/build-release.sh

# Output: build/Translayr-{version}.dmg
```

**Release pipeline includes:**
1. Clean build directory
2. Archive project
3. Export .app
4. Code signing (Developer ID)
5. Create DMG
6. Apple notarization
7. Staple notarization ticket

See [BUILD_RELEASE.md](BUILD_RELEASE.md) for details.

### Build Requirements

- macOS 13.0+
- Xcode 15.0+
- Ollama installed locally

## 🔧 Troubleshooting

### Issue 1: No text detected in other apps

**Symptoms**: Translayr is running but no text is detected

**Fix**:
1. Confirm Accessibility permission
   - System Settings → Privacy & Security → Accessibility → Enable Translayr
2. Restart the target app
3. Restart Translayr
4. Ensure the app isn’t in the skip list

### Issue 2: Ollama connection failed

**Symptoms**: Clicking underline shows no translation

**Fix**:
1. Ensure Ollama is running
   ```bash
   curl http://127.0.0.1:11434/api/tags
   ```
   If it fails, start Ollama:
   ```bash
   ollama serve
   ```
2. Ensure model is downloaded
   ```bash
   ollama list
   ```
   If missing, download:
   ```bash
   ollama pull qwen2.5:3b
   ```
3. Verify model name in Settings

### Issue 3: Underline misaligned

**Symptoms**: Underline is not aligned with text

**Fix**:
- Translayr tracks window movement/resize automatically
- Re-type text in the app if it still misaligns
- Some apps do not expose precise text positioning

### Issue 4: Translation is slow

**Symptoms**: Long wait after clicking underline

**Fix**:
1. First use loads the model (10–30 seconds); subsequent uses are faster
2. Try a lighter model (e.g., `gemma2:2b`)
3. Ensure sufficient memory (8GB+ recommended)
4. Close memory-heavy apps

### Issue 5: Some apps don’t work

**Known limitations**:
- Some apps (e.g., certain Electron apps) may not support Accessibility APIs
- Password fields are not accessible for security reasons
- Some IME input fields may not expose position APIs

## 🛣️ Roadmap

### Completed ✅
- [x] System-wide text monitoring
- [x] Multi-language detection (10 languages)
- [x] Real-time translation
- [x] Floating underline hints
- [x] One-click replacement
- [x] Menu bar integration
- [x] Configurable settings
- [x] Skip app list
- [x] Custom underline colors
- [x] Auto-hide on window movement
- [x] Auto-hide on scrolling
- [x] Multi-screen/space switching detection
- [x] Auto update check (GitHub Releases)
- [x] Release build pipeline (signing + notarization)

## 🤝 Contributing & Community

Contributions are welcome via issues and pull requests:

- [Issues](../../issues)
- [Discussions](../../discussions)
- [Discord](https://discord.com/invite/eGzEaP6TzR)

### Contribution Workflow

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Coding Standards

- Follow Swift official style guidelines
- Add unit tests for new features
- Keep comments clear (bilingual preferred)
- Ensure tests pass before PR submission

### Reporting Issues

Please include:
- macOS version
- Translayr version
- Ollama version and model
- Detailed issue description and reproduction steps
- Relevant logs (if available)

## 📄 License

Released under the [MIT License](LICENSE).

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=everettjf/Translayr&type=Date)](https://star-history.com/#everettjf/Translayr&Date)

---

**Made with ❤️ for macOS**

If Translayr is helpful, please consider giving it a ⭐️!

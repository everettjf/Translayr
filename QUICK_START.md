# Translayr Release - Quick Start Guide

<p align="center">
  <a href="https://discord.com/invite/eGzEaP6TzR"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" /></a>
</p>

5-minute setup, one-command release.

## 📦 Files Created

```
Translayr/
├── scripts/
│   ├── build-release.sh         # 🚀 One-command release build
│   └── sign-and-notarize.sh     # ✍️  Standalone sign + notarize
├── .env.template                 # 🔑 Config template
├── ExportOptions.plist           # ⚙️  Xcode export config
├── BUILD_RELEASE.md              # 📖 Full release guide
└── QUICK_START.md                # ⚡ Quick start (this file)
```

## ⚡ Quick Start (3 Steps)

### 1️⃣ Configure Credentials (First Time Only)

```bash
# Copy template
cp .env.template .env

# Edit config
nano .env  # fill in your Apple Developer credentials
```

**Required information:**
- **Developer ID certificate name** - from Keychain Access
- **Apple ID email**
- **Team ID** (10 chars) - from developer.apple.com
- **App-specific password** - generated at appleid.apple.com

> Tip: See `.env.template` comments for details.

### 2️⃣ Update GitHub Repo Info

Edit `Translayr/Services/UpdateChecker.swift`:

```swift
private let githubOwner = "your-github-username"
private let githubRepo = "Translayr"
```

### 3️⃣ One-Command Build

```bash
# Build version 1.0.0
./scripts/build-release.sh 1.0.0
```

**The script will:**
- Clean build directory
- Update version
- Build archive
- Export app
- Sign app
- Create DMG
- Submit for notarization
- Staple notarization ticket

**Build time:** ~5–15 minutes

**Output:** `build/Translayr-1.0.0.dmg`

---

## 🎯 Release Flow

### Test the DMG
Test on a clean Mac:
```bash
open build/
```

### Create a GitHub Release

1. Go to Releases
2. Click "Create a new release"
3. Tag: `v1.0.0`
4. Upload `Translayr-1.0.0.dmg`
5. Publish

**After users download:**
- Auto update check works ✅
- Menu bar shows update notice ✅
- Click opens download page ✅

---

## 🔧 Common Commands

### Full build (recommended)
```bash
./scripts/build-release.sh 1.0.0
```

### Sign existing .app
```bash
./scripts/sign-and-notarize.sh build/export/Translayr.app
```

### Notarize existing DMG
```bash
./scripts/sign-and-notarize.sh build/Translayr-1.0.0.dmg
```

### Verify code signature
```bash
codesign -vvv --deep --strict build/export/Translayr.app
```

### Validate notarization
```bash
xcrun stapler validate build/Translayr-1.0.0.dmg
```

---

## 🚨 First-Time Checklist

- [ ] Xcode Command Line Tools installed
- [ ] Homebrew installed
- [ ] create-dmg installed (`brew install create-dmg`)
- [ ] Apple Developer account active
- [ ] Developer ID certificate installed
- [ ] `.env` created with credentials
- [ ] `UpdateChecker.swift` repo info updated
- [ ] Scripts have execute permission

---

## 📚 Need More Help?

**Full guide:** `BUILD_RELEASE.md`
- Prerequisites
- Manual build steps
- Troubleshooting
- GitHub Actions automation

**Diagnostics:**
```bash
# Check certificates
security find-identity -v -p codesigning

# Check Xcode
xcode-select -p

# Test env vars
source .env && echo $DEVELOPER_ID_APPLICATION
```

---

## 🎉 After the First Release

1. **Verify auto-update**
   - Run old version
   - Confirm it detects the new release
   - Check the download link

2. **Add Homebrew Cask (optional)**
   ```ruby
   cask "translayr" do
     version "1.0.0"
     url "https://github.com/username/Translayr/releases/download/v1.0.0/Translayr-1.0.0.dmg"
     name "Translayr"
     homepage "https://github.com/username/Translayr"
     app "Translayr.app"
   end
   ```

3. **Set up GitHub Actions (optional)**
   - Automate releases
   - See `BUILD_RELEASE.md`

---

## 💡 Tips

- 🔐 Never commit `.env` to Git (already in .gitignore)
- 📝 Use semantic versioning: `major.minor.patch`
- 🧪 Test DMG on a clean Mac before release
- 📊 Consider analytics (TelemetryDeck or Mixpanel)
- 🐛 Consider crash reporting (Sentry)

---

## Next Steps

1. Complete first-time setup
2. Build and test the first release
3. Publish to GitHub Releases
4. Add analytics and crash reporting
5. Automate with GitHub Actions

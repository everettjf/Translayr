# Translayr Release Build Guide

<p align="center">
  <a href="https://discord.com/invite/eGzEaP6TzR"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" /></a>
</p>

A complete guide to macOS app signing, notarization, and release.

## Table of Contents

- [Prerequisites](#prerequisites)
- [First-Time Setup](#first-time-setup)
- [Build a Release](#build-a-release)
- [Manual Signing and Notarization](#manual-signing-and-notarization)
- [Publish to GitHub](#publish-to-github)
- [Troubleshooting](#troubleshooting)
- [Versioning](#versioning)
- [Automated Release (Advanced)](#automated-release-advanced)
- [Other Distribution Channels](#other-distribution-channels)
- [Resources](#resources)
- [Support](#support)

---

## Prerequisites

### 1. Apple Developer Account

- Paid Apple Developer Program membership ($99/year)
- Sign up: https://developer.apple.com/programs/

### 2. Developer ID Certificate

1. Visit [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click "+" to create a new certificate
3. Choose "Developer ID Application" (for distribution outside the Mac App Store)
4. Create a CSR (Certificate Signing Request)
5. Download and install the certificate in Keychain Access

**Verify the certificate:**
```bash
security find-identity -v -p codesigning
```

You should see something like:
```
1) ABC1234567 "Developer ID Application: Your Name (TEAM_ID)"
```

### 3. Required Tools

#### Xcode Command Line Tools
```bash
xcode-select --install
```

#### Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### create-dmg (for DMG creation)
```bash
brew install create-dmg
```

---

## First-Time Setup

### Step 1: Configure Environment Variables

1. Copy the template:
```bash
cd /path/to/Translayr
cp .env.template .env
```

2. Edit `.env` with your credentials:
```bash
nano .env  # or your preferred editor
```

Required values:

#### a. DEVELOPER_ID_APPLICATION
Open Keychain Access → My Certificates, locate the "Developer ID Application" cert, and copy the full name:
```
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (ABC1234567)"
```

#### b. APPLE_ID
Your Apple ID email:
```
APPLE_ID="your-email@example.com"
```

#### c. TEAM_ID
Find your Team ID at https://developer.apple.com/account → Membership:
```
TEAM_ID="ABC1234567"
```

#### d. APPLE_APP_PASSWORD
**Important:** This is not your Apple ID password.

1. Go to https://appleid.apple.com/account/manage
2. In "Security", create an App-Specific Password
3. Use a label like "Translayr Notarization"
4. Copy the generated password (format: xxxx-xxxx-xxxx-xxxx)

```
APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

### Step 2: Verify Setup

```bash
# Load env vars
source .env

# Verify signing identity
security find-identity -v -p codesigning | grep "$TEAM_ID"

# Verify notarization credentials (no upload)
xcrun notarytool store-credentials "test-profile" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APPLE_APP_PASSWORD"
```

### Step 3: Update UpdateChecker.swift

Edit `Translayr/Services/UpdateChecker.swift` with your repo info:

```swift
private let githubOwner = "your-github-username"
private let githubRepo = "Translayr"
```

### Step 4: Add Execute Permissions

```bash
chmod +x scripts/build-release.sh
chmod +x scripts/sign-and-notarize.sh
```

---

## Build a Release

### Automated Build (Recommended)

One command for build + signing + notarization + packaging:

```bash
./scripts/build-release.sh 1.0.0
```

The script will:
1. Clean build directory
2. Update Info.plist version
3. Build Xcode archive
4. Export .app
5. Code sign
6. Create DMG
7. Upload for notarization
8. Staple notarization ticket

**Expected time:** 5–15 minutes (notarization depends on Apple)

Output DMG:
```
build/Translayr-1.0.0.dmg
```

### Manual Build Steps

For fine-grained control, run steps manually:

#### 1. Archive
```bash
xcodebuild archive \
  -scheme Translayr \
  -configuration Release \
  -archivePath build/Translayr.xcarchive \
  CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)" \
  -allowProvisioningUpdates
```

#### 2. Export App
```bash
xcodebuild -exportArchive \
  -archivePath build/Translayr.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

#### 3. Sign
```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --timestamp \
  build/export/Translayr.app
```

#### 4. Create DMG
```bash
create-dmg \
  --volname "Translayr" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 450 200 \
  build/Translayr-1.0.0.dmg \
  build/export/Translayr.app
```

#### 5. Notarize
```bash
xcrun notarytool submit build/Translayr-1.0.0.dmg \
  --apple-id "your-email@example.com" \
  --team-id "TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  --wait
```

#### 6. Staple
```bash
xcrun stapler staple build/Translayr-1.0.0.dmg
```

---

## Manual Signing and Notarization

If you already have a .app or .dmg, use the standalone script:

### Sign .app and create DMG
```bash
./scripts/sign-and-notarize.sh build/export/Translayr.app
```

### Notarize existing DMG
```bash
./scripts/sign-and-notarize.sh build/Translayr-1.0.0.dmg
```

---

## Publish to GitHub

### Step 1: Test the DMG

Test on a **clean Mac** or a fresh user account:

1. Download DMG
2. Open DMG
3. Drag Translayr.app into Applications
4. Launch from Applications
5. Confirm no "damaged" or "unknown developer" warnings

### Step 2: Create a GitHub Release

#### Option 1: GitHub Web UI

1. Go to your repo
2. Click "Releases" → "Create a new release"
3. Fill release info:

**Tag version:** `v1.0.0`
**Release title:** `Translayr 1.0.0`
**Description:**
```markdown
## What's New

- Added automatic update checking
- Improved translation accuracy
- Bug fixes and performance improvements

## Installation

1. Download `Translayr-1.0.0.dmg` below
2. Open the DMG file
3. Drag Translayr to your Applications folder
4. Launch from Applications

## System Requirements

- macOS 12.0 or later
- Accessibility permissions required for text monitoring

## Known Issues

- First launch may take a few seconds
- Some apps need to be restarted for Translayr to work

---

**Full Changelog**: https://github.com/username/Translayr/compare/v0.9.0...v1.0.0
```

4. Upload `Translayr-1.0.0.dmg`
5. Click "Publish release"

#### Option 2: GitHub CLI

```bash
# Install gh CLI
brew install gh

# Login
gh auth login

# Create release
gh release create v1.0.0 \
  build/Translayr-1.0.0.dmg \
  --title "Translayr 1.0.0" \
  --notes "See full release notes at https://github.com/username/Translayr/releases/tag/v1.0.0"
```

### Step 3: Verify Auto-Update

1. Run the old app version
2. Confirm update is detected
3. Click the update notification
4. Verify it opens the GitHub Releases page

---

## Troubleshooting

### Issue: Signing failed "no identity found"

**Fix:**
```bash
# List available identities
security find-identity -v -p codesigning

# If missing, reinstall certificate
# 1. Download from developer.apple.com
# 2. Double-click .cer to install in Keychain
```

### Issue: Notarization failed "Invalid credentials"

**Check:**
1. Apple ID is correct
2. App-specific password is used (not your regular password)
3. Team ID is correct

**Recreate app-specific password:**
1. https://appleid.apple.com/account/manage
2. Security → App-Specific Passwords
3. Generate a new password and update `.env`

### Issue: Notarization failed "The binary is not signed"

**Fix:**
Ensure you signed before notarizing and used `--options runtime`:
```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --timestamp \
  Translayr.app
```

### Issue: DMG shows "damaged" after download

**Cause:** Not notarized or ticket not stapled

**Fix:**
1. Ensure notarization succeeded
2. Run `xcrun stapler staple Translayr.dmg`
3. Verify: `xcrun stapler validate Translayr.dmg`

### Issue: Xcode not found during build

**Fix:**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Verify
xcode-select -p
```

### Issue: create-dmg not found

**Fix:**
```bash
brew install create-dmg
```

### Issue: UpdateChecker doesn’t detect new releases

**Check:**
1. GitHub owner/repo values in `UpdateChecker.swift`
2. Tag format is `v1.0.0`
3. Release is not marked as prerelease
4. Network connectivity

---

## Versioning

Follow [Semantic Versioning](https://semver.org/):

- **Major**: breaking changes
- **Minor**: backward-compatible features
- **Patch**: backward-compatible bug fixes

Examples:
- `1.0.0` - first stable release
- `1.1.0` - new features
- `1.1.1` - bug fixes
- `2.0.0` - breaking changes

---

## Automated Release (Advanced)

### GitHub Actions

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup environment
        env:
          DEVELOPER_ID_APPLICATION: ${{ secrets.DEVELOPER_ID_APPLICATION }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          TEAM_ID: ${{ secrets.TEAM_ID }}
          APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
        run: |
          echo "DEVELOPER_ID_APPLICATION=$DEVELOPER_ID_APPLICATION" > .env
          echo "APPLE_ID=$APPLE_ID" >> .env
          echo "TEAM_ID=$TEAM_ID" >> .env
          echo "APPLE_APP_PASSWORD=$APPLE_APP_PASSWORD" >> .env

      - name: Build release
        run: |
          chmod +x scripts/build-release.sh
          ./scripts/build-release.sh ${GITHUB_REF#refs/tags/v}

      - name: Upload to release
        uses: softprops/action-gh-release@v1
        with:
          files: build/*.dmg
```

**Configure GitHub Secrets:**
1. Repo Settings → Secrets → Actions
2. Add:
   - `DEVELOPER_ID_APPLICATION`
   - `APPLE_ID`
   - `TEAM_ID`
   - `APPLE_APP_PASSWORD`

---

## Other Distribution Channels

### Homebrew Cask

Submit to Homebrew so users can install via `brew install --cask translayr`:

1. Fork https://github.com/Homebrew/homebrew-cask
2. Create `Casks/translayr.rb`
3. Open a Pull Request

### Setapp

If you want subscription distribution:
- Apply: https://setapp.com/developers
- Benefits: billing, updates, analytics

---

## Resources

- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [create-dmg Docs](https://github.com/create-dmg/create-dmg)
- [Semantic Versioning](https://semver.org/)

---

## Support

If you run into issues:
1. Review the troubleshooting section
2. Check detailed script output
3. Open a GitHub Issue

---

**Last updated:** 2025-01-12

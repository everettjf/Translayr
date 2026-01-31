# Translayr System Service Guide

<p align="center">
  <a href="https://discord.com/invite/eGzEaP6TzR"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" /></a>
</p>

## 🌟 What Are System Services?

Translayr provides **macOS system services**, so you can translate selected text in any app that supports text selection, including:

- **Notes**
- **TextEdit**
- **Safari**
- **Mail**
- **Pages**
- **Xcode**
- And most other macOS apps

## 🚀 Quick Start

### 1. Launch Translayr

Run the app once so the service is registered:

```bash
# Run from Xcode, or
open /path/to/Translayr.app
```

### 2. Refresh Services (First Time)

Refresh the system services cache on first use:

```bash
# Option 1: Restart SystemUIServer (recommended)
killall SystemUIServer

# Option 2: Log out and log in again
# System Settings > Lock Screen > Log Out

# Option 3: Command-line flush
/System/Library/CoreServices/pbs -flush
```

### 3. Start Using It

Now Translayr services should appear in any app’s Services menu.

## 📝 How to Use

### Method 1: Right-Click Menu

1. Select Chinese text in any app
2. Right-click the selection
3. Navigate to **Services** > **Translayr**
4. Choose a service:
   - **Translate to English (Translayr)** - translate and replace
   - **Get Translation Suggestions (Translayr)** - list translation options

### Method 2: Menu Bar

1. Select text
2. Open the app’s menu bar
3. Go to **Services** (or App Name > Services)
4. Select a Translayr service

### Method 3: Keyboard Shortcut (Optional)

You can assign shortcuts to Translayr services:

1. Open **System Settings**
2. Go to **Keyboard** → **Keyboard Shortcuts**
3. Select **Services**
4. Find **Translayr** services
5. Add a shortcut (suggested: `⌘⇧T`)

## 🎯 Examples

### Example 1: Translate in Notes

1. Open Notes
2. Type:
   ```
   人工智能正在改变世界
   ```
3. Select the text
4. Right-click → Services → **Translate to English (Translayr)**
5. The text becomes:
   ```
   Artificial intelligence is changing the world
   ```

### Example 2: Suggestions in TextEdit

1. Open TextEdit
2. Type:
   ```
   机器学习
   ```
3. Select the text
4. Right-click → Services → **Get Translation Suggestions (Translayr)**
5. You’ll see:
   ```
   machine learning
   ```

### Example 3: Use in Browser

1. Select Chinese text in Safari
2. Right-click → Services → Translayr
3. The selection is replaced with translation

## 🔍 Verify Service Registration

### Method 1: System Settings

1. Open **System Settings** → **Keyboard** → **Keyboard Shortcuts**
2. Select **Services**
3. Scroll to **Text** category
4. Translayr services should be listed

### Method 2: Command Line

```bash
# List registered services
/System/Library/CoreServices/pbs -dump_pboard

# Check services database
defaults read pbs NSServicesStatus
```

### Method 3: Practical Test

In TextEdit:
1. Select any Chinese text
2. Right-click the selection
3. Check the Services submenu

## ⚙️ Configuration

### Customize Service Name

Edit `Info.plist` under `NSMenuItem`:

```xml
<key>NSMenuItem</key>
<dict>
    <key>default</key>
    <string>Your Custom Name</string>
</dict>
```

### Customize Shortcut

In `Info.plist`:

```xml
<key>NSKeyEquivalent</key>
<dict>
    <key>default</key>
    <string>T</string>  <!-- ⌘⇧T -->
</dict>
```

Modifier keys:
- Default includes `⌘⇧` (Command + Shift)
- You only need to specify the letter

## 🔧 Troubleshooting

### Issue 1: Translayr not in Services menu

**Fix:**
1. Ensure Translayr has launched at least once
2. Refresh services cache:
   ```bash
   killall SystemUIServer
   ```
3. If still missing, log out and log back in

### Issue 2: Service does nothing

**Possible causes:**
- Ollama not running
- Translayr not running in background
- Model not downloaded

**Fix:**
```bash
ollama serve
ollama list
ollama pull qwen2.5:3b
```

### Issue 3: Slow translation

**Fix:**
1. First translation is slower (model load)
2. Use a smaller model: `gemma2:2b`
3. Keep Translayr running

### Issue 4: Service missing in some apps

**Cause:** Some apps may not support system services.

**Fix:**
- Confirm the app supports text selection
- Some sandboxed apps restrict services
- Try another app to verify

## 💡 Advanced Usage

### Batch Translation

1. Select multiple Chinese lines (separated by line breaks)
2. Use **Get Translation Suggestions**
3. Each line is translated separately

### Combine with Automator

1. Open **Automator**
2. Create a **Quick Action**
3. Add **Run Service**
4. Select a Translayr service
5. Add extra actions (e.g., copy to clipboard)

### Call via AppleScript

```applescript
tell application "System Events"
    keystroke "a" using command down
    delay 0.5
    -- Invoke service via UI scripting
end tell
```

## 📊 Performance Tips

### Optimize Responsiveness

1. **Keep Translayr running**
2. **Warm up the model** with one translation after launch
3. **Use lightweight models**: `gemma2:2b` or `qwen2.5:3b`
4. **Avoid very large selections**

### Expected Performance

| Operation | First Run | Subsequent |
|------|------|------|
| Service call | 2–3s | 1s |
| Short text translation | 3–5s | 1–2s |
| Long text translation | 5–10s | 3–5s |

## 🎓 Best Practices

1. Keep Translayr and Ollama running
2. Test with short text first
3. Set a keyboard shortcut
4. Update models regularly
5. Use suggestions for important translations

## 🔐 Privacy and Security

### Data Handling

- ✅ All translations are local
- ✅ No data sent to the cloud
- ✅ Ollama runs offline
- ✅ Complies with macOS sandboxing

### Permissions

Translayr uses:
- **Network client**: local Ollama (127.0.0.1)
- **Read selection**: access selected text in other apps
- **Write text**: replace translated output

All permissions remain within sandbox constraints.

## 📚 Technical Details

### NSServices Implementation

Translayr uses macOS NSServices:

- **Provider**: `SystemServiceProvider`
- **Methods**:
  - `translateToEnglish(_:userData:error:)`
  - `getTranslationSuggestions(_:userData:error:)`
- **Data transport**: NSPasteboard
- **Concurrency**: Swift async/await

### Service Workflow

```
User selects text
    ↓
System calls service
    ↓
Translayr reads from Pasteboard
    ↓
Ollama translates
    ↓
Result written back to Pasteboard
    ↓
System replaces original text
```

## 🆘 Help

If you run into issues:

1. Check Translayr console output (debug logs)
2. Check system logs in Console.app (search "Translayr")
3. Read README.md and USAGE.md
4. Open a GitHub Issue

## 🎉 Enjoy!

You can now use Translayr across macOS with system services.

Try selecting Chinese text in different apps for seamless translation.

# Translayr Usage Guide

<p align="center">
  <a href="https://discord.com/invite/eGzEaP6TzR"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" /></a>
</p>

## 🚀 Quick Start

### 1. Start Ollama

Before using Translayr, make sure Ollama is running:

```bash
# Start Ollama
ollama serve

# In another terminal, verify it is running
curl http://127.0.0.1:11434/api/tags
```

If you see JSON output, Ollama is running correctly.

### 2. Run Translayr

Open the project in Xcode and run (⌘ + R), or launch the built app.

### 3. Use Translation

1. **Sample text**
   - The app loads a Chinese sample text by default
   - Samples include common technical terms

2. **Click "Check Spelling"**
   - Click the "Check Spelling" toolbar button
   - The app analyzes text

3. **View suggestions**
   - Suggestions appear after a few seconds
   - Each Chinese phrase shows an English translation
   - Suggestions are marked as "AI Translation"

4. **Apply translation**
   - Click a suggestion to replace the original text

## 📝 Examples

### Example 1: Technical Terms

**Input**:
```
人工智能和机器学习是现代科技的重要组成部分。
深度学习模型在图像识别领域取得了突破性进展。
```

**Steps**:
1. Paste text into the editor
2. Click "Check Spelling"
3. Review suggestions

**Expected translations**:
- "人工智能" → "artificial intelligence"
- "机器学习" → "machine learning"
- "深度学习" → "deep learning"
- "图像识别" → "image recognition"

### Example 2: Daily Phrases

**Input**:
```
今天天气很好，我们去公园散步吧。
明天有一个重要的会议需要参加。
```

**Expected translations**:
- "今天" → "today"
- "天气" → "weather"
- "公园" → "park"
- "散步" → "walk"
- "明天" → "tomorrow"
- "会议" → "meeting"

## 🔍 Debugging and Logs

### Console Output

When running in Xcode, you’ll see logs like:

```
LocalModelClient: analyzeText called
Text contains Chinese: true
=== Analyzing Chinese text ===
Text: 这是一个示例文本...
Found 5 Chinese segments in text
Chinese segment: '示例文本' at range 4-8
Translating: '示例文本'
Translation result: '示例文本' -> 'sample text'
Generated 5 translation suggestions
```

### Common Log Messages

| Log | Meaning |
|---------|------|
| `LocalModelClient: analyzeText called` | Start analyzing text |
| `Text contains Chinese: true` | Chinese detected |
| `Found X Chinese segments` | Found X phrases |
| `Translating: 'phrase'` | Translating that phrase |
| `Translation result: 'phrase' -> 'translation'` | Translation success |
| `Generated X translation suggestions` | X suggestions created |

## ⚙️ Custom Configuration

### Change Default Model

Edit `Translayr/Services/OllamaConfig.swift`:

```swift
struct OllamaConfig {
    // Change to another model
    static let defaultModel = "llama3.2:3b"  // or "gemma2:2b"

    // Tune temperature (0.0-1.0)
    static let temperature = 0.2  // lower = more deterministic

    // Other params...
}
```

### Change Default Text

Edit `Translayr/ContentView.swift`:

```swift
@State private var text = """
Your custom Chinese text...
"""
```

### Disable Debug Logs

Comment out `print()` statements in `LocalModelClient.swift`.

## 🔧 Troubleshooting

### Issue 1: No translation suggestions

**Possible causes**:
1. Ollama not running
2. Model not downloaded
3. No Chinese text
4. Phrases shorter than 2 chars

**Fix**:
```bash
curl http://127.0.0.1:11434/api/tags
ollama list
ollama pull qwen2.5:3b
```

### Issue 2: Translation is slow

**Possible causes**:
1. Model loading on first run
2. Large model
3. Hardware limits

**Fix**:
1. First translation is slower; subsequent translations are faster
2. Use a smaller model like `gemma2:2b`
3. Wait for model to finish loading

### Issue 3: Low translation quality

**Possible causes**:
1. Model choice
2. Temperature too high
3. Prompt needs tuning

**Fix**:
1. Try different models (qwen2.5:3b, llama3.2:3b)
2. Adjust `temperature` in `OllamaConfig.swift`
3. Update the prompt in `LocalModelClient.swift`

### Issue 4: Console errors

Common errors:

```
Translation failed for '词组': networkError
```
**Fix**: Ensure Ollama is running

```
Model not found
```
**Fix**: Download the model

```
Ollama error: ...
```
**Fix**: Check error details; usually network or model load issues

## 💡 Tips

### Tip 1: Batch Translation

Translate multiple phrases at once:

```
人工智能
机器学习
深度学习
自然语言处理
计算机视觉
```

### Tip 2: Use Context

Suggestions show context so you can verify accuracy.

### Tip 3: Ignore Suggestions

Click "Ignore" to skip phrases you don’t want to translate.

### Tip 4: Copy Results

After applying suggestions, copy the updated text for reuse.

## 📊 Performance Optimization

### Recommendations

1. **Warm up the model** with a quick translation after launch
2. **Process in batches** for large text
3. **Use lightweight models**: `qwen2.5:3b` or `gemma2:2b`
4. **Disable unused features** like Auto-correct if not needed

### Expected Performance

| Task | Expected Time |
|------|------|
| First model load | 5–10s |
| Translate one phrase | 1–2s |
| Translate 5 phrases | 5–10s |
| Subsequent translations | 0.5–1s per phrase |

## 🎯 Best Practices

1. Keep Ollama running while using Translayr
2. Choose an appropriate model
3. Review translations carefully
4. Leverage context for accuracy
5. Apply suggestions gradually

## 📚 Advanced Usage

### Custom Translation Prompt

Edit `translateChineseToEnglish` in `LocalModelClient.swift`:

```swift
let prompt = """
Translate the following Chinese text to English.
Provide a natural, idiomatic translation.
Focus on technical accuracy for technical terms.

Chinese: \(text)
English:
"""
```

### Add More Languages

Extend `analyzeText` to detect other languages and route to translations.

### Integrate Other Models

Modify `LocalModelClient` to support other local models or services.

---

Need help? See README.md or open a GitHub Issue.

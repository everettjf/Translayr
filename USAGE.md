# Translayr 使用指南

## 🚀 快速开始

### 1. 启动 Ollama

在使用 Translayr 之前，请确保 Ollama 服务正在运行：

```bash
# 启动 Ollama 服务
ollama serve

# 在另一个终端窗口中，验证服务是否运行
curl http://127.0.0.1:11434/api/tags
```

如果看到 JSON 响应，说明 Ollama 已经正常运行。

### 2. 运行 Translayr

在 Xcode 中打开项目并运行（⌘ + R），或者运行已编译的应用。

### 3. 使用翻译功能

1. **查看示例文本**
   - 应用启动时会自动加载中文示例文本
   - 示例包含常见的技术词汇

2. **点击 "Check Spelling"**
   - 点击工具栏的 "Check Spelling" 按钮
   - 应用会开始分析文本

3. **查看翻译建议**
   - 几秒后会弹出建议窗口
   - 每个中文词组都会显示英文翻译
   - 建议标记为 "AI Translation" 来源

4. **应用翻译**
   - 点击任意翻译建议
   - 原文会被替换为英文翻译

## 📝 使用示例

### 示例 1: 技术术语翻译

**输入**:
```
人工智能和机器学习是现代科技的重要组成部分。
深度学习模型在图像识别领域取得了突破性进展。
```

**操作**:
1. 将文本粘贴到编辑器
2. 点击 "Check Spelling"
3. 查看建议列表

**预期结果**:
- "人工智能" → "artificial intelligence"
- "机器学习" → "machine learning"
- "深度学习" → "deep learning"
- "图像识别" → "image recognition"
- 等等...

### 示例 2: 日常用语翻译

**输入**:
```
今天天气很好，我们去公园散步吧。
明天有一个重要的会议需要参加。
```

**预期结果**:
- "今天" → "today"
- "天气" → "weather"
- "公园" → "park"
- "散步" → "walk"
- "明天" → "tomorrow"
- "会议" → "meeting"

## 🔍 调试和日志

### 查看控制台输出

在 Xcode 中运行时，可以在控制台看到详细的调试信息：

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

### 常见日志信息

| 日志信息 | 含义 |
|---------|------|
| `LocalModelClient: analyzeText called` | 开始分析文本 |
| `Text contains Chinese: true` | 检测到中文 |
| `Found X Chinese segments` | 找到 X 个中文词组 |
| `Translating: '词组'` | 正在翻译该词组 |
| `Translation result: '词组' -> 'translation'` | 翻译成功 |
| `Generated X translation suggestions` | 生成了 X 个翻译建议 |

## ⚙️ 自定义配置

### 修改默认模型

编辑 `Translayr/Services/OllamaConfig.swift`:

```swift
struct OllamaConfig {
    // 更改为其他模型
    static let defaultModel = "llama3.2:3b"  // 或 "gemma2:2b"

    // 调整温度参数（0.0-1.0）
    static let temperature = 0.2  // 更低 = 更确定的翻译

    // 其他参数...
}
```

### 修改默认文本

编辑 `Translayr/ContentView.swift`:

```swift
@State private var text = """
你的自定义中文文本...
"""
```

### 禁用调试输出

在 `LocalModelClient.swift` 中注释掉所有 `print()` 语句。

## 🔧 故障排除

### 问题 1: 没有生成翻译建议

**可能原因**:
1. Ollama 服务未运行
2. 模型未下载
3. 文本中没有中文
4. 中文词组少于2个字符

**解决方案**:
```bash
# 检查 Ollama 是否运行
curl http://127.0.0.1:11434/api/tags

# 检查模型是否存在
ollama list

# 如果模型不存在，下载它
ollama pull qwen2.5:3b
```

### 问题 2: 翻译速度慢

**可能原因**:
1. 第一次运行时需要加载模型
2. 模型太大
3. 硬件性能限制

**解决方案**:
1. 第一次翻译会慢一些，之后会快很多
2. 使用更小的模型，如 `gemma2:2b`
3. 等待模型加载完成

### 问题 3: 翻译质量不佳

**可能原因**:
1. 模型选择不当
2. 温度参数设置不合理
3. 提示词需要优化

**解决方案**:
1. 尝试不同的模型（qwen2.5:3b, llama3.2:3b）
2. 调整 `OllamaConfig.swift` 中的 `temperature` 参数
3. 修改 `LocalModelClient.swift` 中的翻译提示词

### 问题 4: 控制台显示错误

**常见错误**:

```
Translation failed for '词组': networkError
```
**解决**: 检查 Ollama 是否正在运行

```
Model not found
```
**解决**: 下载所需的模型

```
Ollama error: ...
```
**解决**: 查看具体错误信息，通常是网络或模型加载问题

## 💡 使用技巧

### 技巧 1: 批量翻译

将多个中文词组放在一起，一次性翻译：

```
人工智能
机器学习
深度学习
自然语言处理
计算机视觉
```

### 技巧 2: 查看上下文

建议窗口会显示每个词组的上下文，帮助你理解翻译是否准确。

### 技巧 3: 忽略不需要的建议

如果某些词组不需要翻译，可以点击 "Ignore" 按钮忽略。

### 技巧 4: 复制翻译结果

应用建议后，整个文本会更新。你可以复制修改后的文本用于其他用途。

## 📊 性能优化

### 优化建议

1. **预热模型**: 第一次运行时输入简单文本让模型预热
2. **分批处理**: 对于大量文本，分批处理效果更好
3. **使用轻量模型**: 日常使用推荐 `qwen2.5:3b` 或 `gemma2:2b`
4. **关闭不需要的功能**: 如果不需要系统拼写检查，可以关闭 Auto-correct

### 预期性能

| 操作 | 预期时间 |
|------|---------|
| 首次加载模型 | 5-10秒 |
| 翻译单个词组 | 1-2秒 |
| 翻译5个词组 | 5-10秒 |
| 后续翻译 | 0.5-1秒/词组 |

## 🎯 最佳实践

1. **保持 Ollama 运行**: 在使用 Translayr 期间始终保持 Ollama 运行
2. **选择合适的模型**: 根据需求选择模型大小和质量的平衡
3. **检查翻译结果**: AI 翻译可能不完美，请检查并调整
4. **利用上下文**: 使用上下文信息判断翻译是否准确
5. **逐步替换**: 不要一次性应用所有建议，逐个检查和应用

## 📚 进阶使用

### 自定义翻译提示词

编辑 `LocalModelClient.swift` 中的 `translateChineseToEnglish` 方法：

```swift
let prompt = """
Translate the following Chinese text to English.
Provide a natural, idiomatic translation.
Focus on technical accuracy for technical terms.

Chinese: \(text)
English:
"""
```

### 添加更多语言支持

修改 `analyzeText` 方法，添加其他语言的检测和翻译逻辑。

### 集成其他 AI 模型

可以修改 `LocalModelClient` 来支持其他 AI 服务或本地模型。

---

**需要帮助？** 请查看 README.md 或创建 GitHub Issue。

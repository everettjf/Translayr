# Spello - AI-Powered Spelling and Translation for macOS

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" />
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" />
  <img src="https://img.shields.io/badge/Xcode-15.0+-blue.svg" />
</p>

Spello 是一款专为 macOS 设计的智能拼写检查和翻译工具。它结合了 macOS 原生的拼写检查能力和本地 AI 模型（Ollama），为用户提供强大的拼写纠错和中英翻译功能。

## ✨ 主要特性

- **🔍 智能拼写检查**: 利用 macOS 原生 NSSpellChecker API，支持多语言拼写检查
- **🤖 AI 翻译**: 集成 Ollama 本地 AI 模型，提供中文到英文的智能翻译
- **🔒 隐私保护**: 所有处理都在本地完成，不发送数据到云端
- **⚡️ 实时检查**: 在输入时实时标记拼写错误
- **📝 上下文建议**: 提供上下文感知的拼写和翻译建议
- **🎨 简洁界面**: 直观的用户界面，易于使用
- **📚 词典管理**: 支持添加自定义词汇到用户词典

## 🎯 核心功能

### 拼写检查

- 实时拼写错误高亮
- 多种拼写建议
- 右键菜单快速修正
- 忽略词和学习词功能
- 支持多语言

### AI 翻译

- **自动检测中文**: 自动识别文本中的中文内容
- **智能翻译**: 使用 Ollama 本地模型翻译中文到英文
- **词级翻译**: 对每个中文词或短语提供翻译建议
- **一键替换**: 点击建议即可替换原文

## 系统要求

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- [Ollama](https://ollama.ai) 已安装（用于 AI 翻译功能）

## 🚀 快速开始

### 安装 Ollama

1. 安装 Ollama:
```bash
brew install ollama
```

2. 下载推荐的翻译模型（选择其一）:
```bash
# 推荐：轻量级，适合快速翻译
ollama pull qwen2.5:3b

# 备选：平衡性能和准确度
ollama pull llama3.2:3b

# 备选：超轻量级
ollama pull gemma2:2b
```

3. 启动 Ollama 服务:
```bash
ollama serve
```

### 构建项目

1. 克隆仓库:
```bash
git clone <your-repo-url>
cd Spello
```

2. 打开项目:
```bash
open Spello.xcodeproj
```

3. 在 Xcode 中构建并运行:
   - 按 `⌘ + R` 运行项目
   - 或选择 Product > Run

## 📖 使用指南

### 快速开始

1. **确保 Ollama 运行**:
   ```bash
   ollama serve
   ```

2. **启动应用**:
   - 打开 Spello 应用
   - 应用会自动加载中文示例文本

3. **翻译中文**:
   - 点击 "Check Spelling" 按钮
   - 等待 AI 分析（第一次可能需要几秒加载模型）
   - 查看翻译建议列表
   - 点击建议应用翻译

### AI 翻译功能说明

**AI 翻译默认启用**，会自动检测文本中的中文并提供英文翻译：

- ✅ **自动检测**: 自动识别2个字以上的中文词组
- ✅ **智能分词**: 将文本分割成有意义的词组
- ✅ **实时翻译**: 使用 Ollama 本地模型进行翻译
- ✅ **一键替换**: 点击翻译建议即可替换原文

**示例文本**：
```
这是一个示例文本。你可以在这里输入或粘贴中文文本，应用会自动为你提供英文翻译建议。

试试输入一些中文词汇，比如"人工智能"、"机器学习"、"深度学习"等，看看翻译效果。
```

### 调试输出

应用会在控制台输出详细的调试信息，包括：
- 检测到的中文片段
- 分词结果
- 翻译请求和响应
- 生成的建议数量

### 配置选项

在工具栏中可以配置：

- **Auto-correct**: 启用/禁用自动拼写纠正
- **Language**: 选择拼写检查语言或自动检测

## 项目结构

```
Spello/
├── Spello/
│   ├── Models/
│   │   └── Suggestion.swift           # 建议数据模型
│   ├── Protocols/
│   │   └── SpellAnalyzing.swift       # 拼写分析协议
│   ├── Services/
│   │   ├── SpellService.swift         # 核心拼写服务
│   │   └── LocalModelClient.swift     # 本地AI模型客户端
│   ├── Views/
│   │   ├── SpellCheckedTextView.swift # 拼写检查文本视图
│   │   └── SuggestionsView.swift      # 建议显示视图
│   ├── ContentView.swift              # 主界面
│   └── SpelloApp.swift               # 应用入口
├── SpelloTests/                       # 单元测试
└── README.md                         # 项目说明
```

## ⚙️ 配置

### Ollama 配置

在 `Spello/Services/OllamaConfig.swift` 中可以自定义配置：

```swift
struct OllamaConfig {
    // Ollama 服务器地址
    static let host = "http://127.0.0.1"
    static let port = 11434

    // 使用的模型
    static let defaultModel = "qwen2.5:3b"

    // 生成参数
    static let temperature = 0.3  // 降低可获得更确定的翻译
    static let topP = 0.9
    static let topK = 40
}
```

### 推荐模型

| 模型 | 大小 | 速度 | 质量 | 适用场景 |
|------|------|------|------|----------|
| qwen2.5:3b | ~2GB | ⚡⚡⚡ | ⭐⭐⭐ | 日常翻译，推荐 |
| llama3.2:3b | ~2GB | ⚡⚡ | ⭐⭐⭐⭐ | 高质量翻译 |
| gemma2:2b | ~1.5GB | ⚡⚡⚡⚡ | ⭐⭐ | 快速翻译 |

## 🔧 故障排除

### Ollama 连接失败

如果 AI 翻译功能无法工作：

1. 检查 Ollama 是否运行:
```bash
curl http://127.0.0.1:11434/api/tags
```

2. 检查模型是否已下载:
```bash
ollama list
```

3. 查看应用日志中的错误信息

### 模型未找到

如果看到 "Model not found" 错误：

1. 确认模型已下载:
```bash
ollama pull qwen2.5:3b
```

2. 检查 `OllamaConfig.swift` 中的模型名称是否正确

## 测试

运行单元测试：
```bash
# 在Xcode中使用快捷键
Cmd+U

# 或使用命令行
xcodebuild test -scheme Spello -destination 'platform=macOS'
```

测试覆盖：
- SpellService功能测试
- 建议合并和去重逻辑测试
- 文本替换正确性测试
- 本地模型客户端测试

## 📋 技术栈

- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI + AppKit (NSTextView)
- **AI 集成**: [ollama-swift](https://github.com/mattt/ollama-swift)
- **拼写检查**: NSSpellChecker (macOS 原生)
- **架构**: MVVM

## 🛣️ 路线图

- [ ] 支持更多语言对翻译
- [ ] 批量文件处理
- [ ] 自定义翻译提示词
- [ ] 翻译历史记录
- [ ] 键盘快捷键
- [ ] 导出/导入词典
- [ ] 深色模式优化
- [ ] 菜单栏快捷访问

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 🙏 致谢

- [ollama-swift](https://github.com/mattt/ollama-swift) - Ollama Swift 客户端
- [Ollama](https://ollama.ai) - 本地 AI 模型运行时
- Apple NSSpellChecker - macOS 拼写检查 API

## 📧 联系方式

如有问题或建议，欢迎创建 [Issue](../../issues)。

---

Made with ❤️ for macOS
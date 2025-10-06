# Spello - macOS 智能拼写检查和翻译工具

## 项目概述

Spello 是一款专为 macOS 设计的智能拼写检查和翻译应用程序。它利用 macOS 系统的原生拼写检查能力，并集成了本地 AI 模型（通过 Ollama）来提供更智能的拼写建议和翻译功能。

### 核心功能

1. **系统拼写检查**
   - 利用 macOS 原生的 `NSSpellChecker` API
   - 支持多语言拼写检查
   - 实时拼写错误高亮显示
   - 上下文感知的拼写建议

2. **AI 增强翻译**
   - 集成 Ollama 本地 AI 模型
   - 中文到英文的智能翻译
   - 通过拼写检查接口提供翻译建议
   - 支持离线使用，保护隐私

3. **用户界面**
   - 简洁直观的文本编辑器
   - 实时拼写检查和纠错
   - 建议列表展示
   - 支持一键应用建议或添加到词典

## 技术架构

### 主要组件

#### 1. 模型层 (Models)
- **Suggestion.swift**: 拼写建议数据模型，包含错误词、建议列表、上下文等信息

#### 2. 服务层 (Services)
- **SpellService.swift**: 核心拼写检查服务
  - 系统拼写检查
  - AI 模型集成
  - 建议合并和去重
  - 词典管理

- **LocalModelClient.swift**: Ollama 本地模型客户端
  - 与 Ollama API 通信
  - 翻译请求处理
  - 错误处理和重试逻辑

#### 3. 视图层 (Views)
- **ContentView.swift**: 主界面
  - 文本编辑器
  - 设置面板
  - 状态栏

- **SpellCheckedTextView.swift**: 文本编辑器视图
  - 基于 NSTextView 的自定义编辑器
  - 实时拼写检查
  - 右键菜单集成

- **SuggestionsView.swift**: 建议列表视图
  - 展示所有拼写问题
  - 支持快速应用建议
  - 管理忽略词和词典

#### 4. 协议层 (Protocols)
- **SpellAnalyzing.swift**: 拼写分析协议
  - 定义拼写检查服务的标准接口
  - 支持依赖注入和测试

## Ollama 集成

### 使用的库
项目使用 [ollama-swift](https://github.com/mattt/ollama-swift) 库来与 Ollama 进行交互。

### 翻译工作流程

1. **用户输入中文文本**
   - 用户在编辑器中输入中文

2. **系统拼写检查**
   - 系统识别为非英文单词

3. **AI 翻译请求**
   - 发送到 Ollama 本地模型
   - 请求英文翻译

4. **建议展示**
   - 将翻译结果作为拼写建议展示
   - 用户可以一键应用翻译

5. **文本替换**
   - 用户选择翻译建议
   - 自动替换原中文文本

### Ollama 模型配置

推荐使用以下模型之一：
- `qwen2.5:3b` - 轻量级，适合快速翻译
- `llama3.2:3b` - 平衡性能和准确度
- `gemma2:2b` - 超轻量级选项

## 数据流

```
用户输入文本
    ↓
SpellCheckedTextView (实时检查)
    ↓
SpellService.checkFullText()
    ├─→ scanSystem() → 系统拼写检查
    └─→ analyzeWithLocalModel() → Ollama 翻译
    ↓
merge() → 合并建议
    ↓
SuggestionsView (展示建议)
    ↓
用户选择建议
    ↓
applyReplacement() → 应用到文本
```

## 特性

### 已实现
- ✅ 系统拼写检查集成
- ✅ 多语言支持
- ✅ 实时拼写纠错
- ✅ 建议管理（忽略、添加到词典）
- ✅ Ollama 集成框架
- ✅ 上下文感知建议
- ✅ 自定义文本编辑器

### 核心功能
- ✅ 中文到英文翻译
- ✅ 智能建议合并
- ✅ 离线工作模式
- ✅ 隐私保护（本地处理）

## 开发指南

### 环境要求
- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+
- Ollama 已安装并运行

### Ollama 设置

1. **安装 Ollama**
   ```bash
   # 从 https://ollama.ai 下载安装
   brew install ollama
   ```

2. **下载模型**
   ```bash
   ollama pull qwen2.5:3b
   ```

3. **启动 Ollama 服务**
   ```bash
   ollama serve
   ```

### 构建项目

```bash
# 克隆项目
git clone <repository-url>

# 打开项目
open Spello.xcodeproj

# 构建并运行
⌘ + R
```

## 测试

项目包含单元测试覆盖：
- `SpellServiceTests.swift` - 拼写服务测试
- `SuggestionTests.swift` - 建议模型测试
- `LocalModelClientTests.swift` - Ollama 客户端测试

运行测试：
```bash
⌘ + U
```

## 配置选项

### 应用设置
- **自动更正**: 启用/禁用自动拼写纠正
- **AI 建议**: 启用/禁用 Ollama 翻译功能
- **语言选择**: 指定拼写检查语言或自动检测

### Ollama 配置
在 `LocalModelClient.swift` 中可以配置：
- API 端点 (默认: `http://127.0.0.1:11434`)
- 超时设置
- 使用的模型名称
- 请求参数（温度、最大 token 等）

## 隐私和安全

- **本地处理**: 所有数据在本地处理，不发送到云端
- **沙盒环境**: 应用在 macOS 沙盒中运行
- **用户控制**: 用户完全控制何时启用 AI 功能

## 未来改进

- [ ] 支持更多语言对翻译
- [ ] 批量处理模式
- [ ] 自定义 AI 提示词
- [ ] 翻译历史记录
- [ ] 快捷键支持
- [ ] 导出/导入词典
- [ ] 主题定制

## 技术栈

- **语言**: Swift
- **UI 框架**: SwiftUI + AppKit (NSTextView)
- **AI 集成**: Ollama (ollama-swift)
- **拼写检查**: NSSpellChecker
- **架构**: MVVM

## 许可证

根据项目许可证发布。

## 贡献

欢迎贡献！请查看贡献指南。

## 联系方式

如有问题或建议，请创建 issue。

---

**注意**: 确保在使用 AI 翻译功能前已正确安装和配置 Ollama。

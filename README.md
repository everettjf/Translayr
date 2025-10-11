# Spello - 系统级智能翻译助手

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" />
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" />
  <img src="https://img.shields.io/badge/Xcode-15.0+-blue.svg" />
  <img src="https://img.shields.io/badge/Ollama-Local%20AI-green.svg" />
</p>

Spello 是一款专为 macOS 设计的**系统级智能翻译助手**。它能实时监控任何应用中的文本输入，自动检测多种语言并提供即时翻译。通过结合 macOS Accessibility API 和本地 AI 模型（Ollama），Spello 为用户提供了一个强大、私密且流畅的跨应用翻译体验。

## ✨ 核心特性

### 🌐 系统级监控
- **跨应用监控**: 在任何 macOS 应用中自动检测和翻译文本（Notes、TextEdit、Safari、Chrome 等）
- **实时文本检测**: 自动识别文本输入框中的内容，无需手动触发
- **智能文本分析**: 自动分词并识别句子和词组
- **应用白名单**: 可配置跳过列表，排除不需要监控的应用

### 🤖 智能翻译
- **多语言支持**: 支持世界上使用人数最多的 10 种语言
  - 中文、英语、西班牙语、印地语、阿拉伯语、法语、孟加拉语、俄语、葡萄牙语、印尼语
- **本地 AI 模型**: 使用 Ollama 提供高质量翻译，无需联网
- **双向翻译**: 可自定义源语言和目标语言
- **上下文感知**: 根据完整句子或词组提供准确翻译

### 🎨 优雅的用户界面
- **浮动下划线**: 在检测到的文本下方显示彩色下划线提示
- **鼠标悬停效果**: 悬停时高亮显示，提供视觉反馈
- **弹窗式翻译**: 点击下划线即显示翻译结果弹窗
- **一键替换**: 点击翻译结果直接在原应用中替换文本
- **自适应位置**: 翻译弹窗智能定位，避免遮挡文本

### 🔒 隐私保护
- **完全本地处理**: 所有翻译在本地完成，数据不离开你的设备
- **无网络依赖**: 不需要云服务或互联网连接
- **权限可控**: 用户完全掌控辅助功能权限

### ⚙️ 丰富的配置选项
- **语言选择**: 自定义检测语言和目标翻译语言
- **颜色自定义**: 可配置下划线颜色
- **应用过滤**: 设置跳过监控的应用列表
- **模型选择**: 支持多种 Ollama 模型
- **菜单栏集成**: 便捷的菜单栏快速访问

## 📸 使用场景

- **写作辅助**: 在任何文本编辑器中实时翻译外语词汇
- **学习工具**: 浏览网页时即时翻译不认识的词汇
- **邮件撰写**: 在邮件客户端中快速翻译句子
- **代码注释**: 帮助编写多语言代码注释
- **社交媒体**: 在聊天应用中翻译消息

## 🚀 快速开始

### 系统要求
- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本（用于构建）
- [Ollama](https://ollama.ai) 已安装并运行

### 1. 安装 Ollama

```bash
# 使用 Homebrew 安装
brew install ollama

# 下载推荐的翻译模型（选择其一）
ollama pull qwen2.5:3b      # 推荐：轻量级，适合快速翻译
ollama pull llama3.2:3b     # 备选：平衡性能和准确度
ollama pull gemma2:2b       # 备选：超轻量级

# 启动 Ollama 服务
ollama serve
```

### 2. 构建并运行 Spello

```bash
# 克隆项目
git clone <your-repo-url>
cd Spello

# 在 Xcode 中打开项目
open Spello.xcodeproj

# 在 Xcode 中按 ⌘ + R 运行
```

### 3. 授予辅助功能权限

首次运行时，Spello 会请求辅助功能权限：

1. 系统会自动弹出权限请求对话框
2. 点击 "Open System Settings"
3. 在 **系统设置 → 隐私与安全性 → 辅助功能** 中启用 Spello
4. 重启 Spello 以激活监控功能

### 4. 开始使用

1. **确保 Ollama 服务运行中**
   ```bash
   ollama serve
   ```

2. **在设置中配置语言**
   - 点击菜单栏中的 Spello 图标
   - 选择 "Settings"
   - 在 "Language" 标签中选择源语言和目标语言

3. **在任何应用中输入文本**
   - 在支持的应用中输入或粘贴文本
   - Spello 会自动检测目标语言并显示下划线
   - 点击下划线查看翻译
   - 点击翻译结果即可替换原文

## 📖 详细使用指南

### 支持的语言

| 语言 | 代码 | 最小检测长度 | Unicode 模式 |
|------|------|------------|-------------|
| 中文 | zh | 2 字 | CJK 统一汉字 |
| 英语 | en | 4 字母 | 拉丁字母 |
| 西班牙语 | es | 3 字母 | 拉丁字母 + 特殊字符 |
| 印地语 | hi | 2 字符 | 天城文 |
| 阿拉伯语 | ar | 3 字符 | 阿拉伯字母 |
| 法语 | fr | 3 字母 | 拉丁字母 + 法语特殊字符 |
| 孟加拉语 | bn | 2 字符 | 孟加拉文 |
| 俄语 | ru | 3 字母 | 西里尔字母 |
| 葡萄牙语 | pt | 3 字母 | 拉丁字母 + 葡语特殊字符 |
| 印尼语 | id | 4 字母 | 拉丁字母 |

### 工作原理

```
用户在任何应用中输入文本
          ↓
AccessibilityMonitor 监控文本变化
          ↓
SpellCheckMonitor 检测目标语言
          ↓
OverlayWindow 显示下划线标记
          ↓
用户点击下划线
          ↓
LocalModelClient 调用 Ollama 翻译
          ↓
显示翻译弹窗
          ↓
用户选择翻译结果
          ↓
在原应用中替换文本
```

### 高级配置

#### 自定义跳过应用列表

在 "Skip Apps" 设置中，可以配置不需要监控的应用：

```
Xcode, Terminal, iTerm, 1Password
```

用逗号分隔应用名称（不区分大小写）。

#### 自定义下划线颜色

在 "Colors" 设置中选择喜欢的下划线颜色：
- 红色（默认）
- 蓝色
- 绿色
- 紫色
- 橙色

#### 选择 AI 模型

在 "Models" 设置中选择 Ollama 模型：
- 输入模型名称（如 `qwen2.5:3b`）
- 点击 "Save" 保存设置

## 🏗️ 项目架构

```
Spello/
├── Spello/
│   ├── SpelloApp.swift              # 应用入口，菜单栏集成
│   ├── ContentView.swift            # 主界面
│   │
│   ├── Models/
│   │   └── Suggestion.swift         # 建议数据模型
│   │
│   ├── Protocols/
│   │   └── SpellAnalyzing.swift     # 拼写分析协议
│   │
│   ├── Services/
│   │   ├── AccessibilityMonitor.swift    # 辅助功能监控器（文本获取）
│   │   ├── SpellCheckMonitor.swift       # 拼写检查监控器（核心协调）
│   │   ├── SpellService.swift            # 拼写服务（翻译逻辑）
│   │   ├── LocalModelClient.swift        # Ollama 客户端
│   │   ├── SystemServiceProvider.swift   # 系统服务提供者
│   │   └── LanguageConfig.swift          # 语言配置管理
│   │
│   ├── Views/
│   │   ├── OverlayWindow.swift          # 浮动下划线窗口
│   │   ├── MenuBarView.swift            # 菜单栏视图
│   │   │
│   │   └── SettingsView/
│   │       ├── SettingsView.swift           # 设置主视图
│   │       ├── GeneralSettingsView.swift    # 通用设置
│   │       ├── LanguageSettingsView.swift   # 语言设置
│   │       ├── ColorSettingsView.swift      # 颜色设置
│   │       ├── SkipAppsSettingsView.swift   # 跳过应用设置
│   │       ├── ModelsSettingsView.swift     # 模型设置
│   │       ├── PreferencesSection.swift     # 偏好设置组件
│   │       └── AboutView.swift              # 关于页面
│   │
│   └── Info.plist                   # 应用配置
│
├── SpelloTests/                     # 单元测试
├── README.md                        # 项目说明（本文件）
├── DOCUMENT.md                      # 详细文档
├── USAGE.md                         # 使用指南
├── SYSTEM_SERVICE.md                # 系统服务集成说明
└── Agents.md                        # AI Agent 相关文档
```

## ⚙️ 配置说明

### Ollama 配置

配置信息存储在 `UserDefaults` 中：

```swift
// 保存模型名称
UserDefaults.standard.set("qwen2.5:3b", forKey: "ollamaModel")

// Ollama 服务器默认地址
// http://127.0.0.1:11434
```

### 推荐模型对比

| 模型 | 大小 | 速度 | 质量 | 内存占用 | 适用场景 |
|------|------|------|------|---------|----------|
| qwen2.5:3b | ~2GB | ⚡⚡⚡ | ⭐⭐⭐⭐ | ~4GB | 日常翻译，推荐 ✅ |
| llama3.2:3b | ~2GB | ⚡⚡ | ⭐⭐⭐⭐⭐ | ~4GB | 高质量翻译 |
| gemma2:2b | ~1.5GB | ⚡⚡⚡⚡ | ⭐⭐⭐ | ~3GB | 快速翻译、低内存设备 |
| phi3:3.8b | ~2.3GB | ⚡⚡ | ⭐⭐⭐⭐ | ~4.5GB | 平衡性能 |

## 🔧 故障排除

### 问题 1: 无法监控其他应用的文本

**症状**: Spello 运行中但没有检测到其他应用的文本

**解决方案**:
1. 确认已授予辅助功能权限
   - 系统设置 → 隐私与安全性 → 辅助功能 → 启用 Spello
2. 尝试重启目标应用
3. 尝试重启 Spello
4. 检查目标应用是否在跳过列表中

### 问题 2: Ollama 连接失败

**症状**: 点击下划线后没有翻译结果

**解决方案**:
1. 确认 Ollama 服务正在运行
   ```bash
   curl http://127.0.0.1:11434/api/tags
   ```
   如果返回错误，启动 Ollama：
   ```bash
   ollama serve
   ```
2. 确认模型已下载
   ```bash
   ollama list
   ```
   如果没有，下载模型：
   ```bash
   ollama pull qwen2.5:3b
   ```
3. 检查模型名称是否正确配置

### 问题 3: 下划线位置不准确

**症状**: 下划线没有对齐到文本下方

**解决方案**:
- Spello 会自动跟踪窗口移动和调整大小
- 如果位置仍不准确，尝试在该应用中重新输入文本
- 某些应用可能不支持精确的文本位置 API

### 问题 4: 翻译速度慢

**症状**: 点击下划线后需要等待很久才显示翻译

**解决方案**:
1. 首次使用会加载模型（10-30秒），之后会快很多
2. 尝试使用更轻量的模型（如 `gemma2:2b`）
3. 确保 Mac 有足够的内存（推荐 8GB+）
4. 关闭其他占用内存的应用

### 问题 5: 某些应用无法工作

**已知限制**:
- 某些应用可能不支持辅助功能 API（如某些 Electron 应用）
- 密码输入框出于安全原因无法访问
- 某些原生输入法输入框可能不支持

## 📋 技术栈

- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI + AppKit
- **AI 集成**: [Ollama](https://ollama.ai)
- **辅助功能**: macOS Accessibility API (AX API)
- **系统集成**: NSService, MenuBarExtra
- **架构模式**: MVVM + Combine

## 🛣️ 开发路线图

### 已完成 ✅
- [x] 系统级文本监控
- [x] 多语言检测（10 种语言）
- [x] 实时翻译
- [x] 浮动下划线提示
- [x] 一键文本替换
- [x] 菜单栏集成
- [x] 多种配置选项
- [x] 应用跳过列表
- [x] 自定义颜色

### 计划中 🎯
- [ ] 快捷键支持（全局热键）
- [ ] 翻译历史记录
- [ ] 批量翻译
- [ ] 文档翻译（PDF, Word）
- [ ] 离线词典集成
- [ ] 自定义翻译提示词模板
- [ ] 多模型对比翻译
- [ ] 导出/导入词典
- [ ] 深色模式优化
- [ ] 更多语言支持
- [ ] 系统通知集成

### 未来展望 🌟
- [ ] Safari 浏览器扩展
- [ ] Chrome 浏览器扩展
- [ ] iOS/iPadOS 版本
- [ ] iCloud 同步设置
- [ ] 团队协作功能

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

### 如何贡献

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 代码规范

- 遵循 Swift 官方编码规范
- 为新功能添加单元测试
- 保持代码注释清晰（中英双语更佳）
- 确保所有测试通过后再提交 PR

### 报告问题

在创建 Issue 时，请提供：
- macOS 版本
- Spello 版本
- Ollama 版本和模型
- 详细的问题描述和复现步骤
- 相关的日志输出（如有）

## 🙏 致谢

- [Ollama](https://ollama.ai) - 优秀的本地 AI 模型运行时
- [ollama-swift](https://github.com/mattt/ollama-swift) - Swift 版 Ollama 客户端（如使用）
- Apple NSSpellChecker - macOS 原生拼写检查 API
- macOS Accessibility API - 强大的系统辅助功能

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)。

## 📧 联系方式

- 创建 [Issue](../../issues) 报告问题或提出建议
- 查看 [Discussions](../../discussions) 参与讨论

---

**Made with ❤️ for macOS**

如果觉得 Spello 有用，请给个 ⭐️ Star！

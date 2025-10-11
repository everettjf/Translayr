# Translayr 技术文档

## 项目概述

Translayr 是一个 macOS 应用程序，能够实时监控其他应用中的中文文本，并提供 AI 翻译功能。用户可以在任何应用中输入中文，Translayr 会自动检测并在文字下方显示红色下划线，点击后可查看英文翻译建议。

## 核心功能

1. **系统级文本监控** - 使用 macOS Accessibility API 监控其他应用的文本输入
2. **中文文本检测** - 自动识别中文句子和词组
3. **浮动下划线显示** - 在其他应用窗口上方显示透明 overlay，标记中文文本
4. **AI 翻译** - 使用本地 Ollama 模型提供翻译建议
5. **窗口位置追踪** - 当用户移动窗口时，下划线自动跟随更新

## 核心架构

### 三层架构设计

```
┌─────────────────────────────────────────┐
│         SpellCheckMonitor               │  ← 核心协调层
│  - 订阅文本变化                          │
│  - 检测中文内容                          │
│  - 协调 overlay 显示                     │
└────────────┬────────────────────────────┘
             │
             ├──────────────┬──────────────┐
             ▼              ▼              ▼
┌────────────────┐  ┌──────────────┐  ┌──────────────┐
│ Accessibility  │  │  Overlay     │  │  Spell       │
│ Monitor        │  │  Window      │  │  Service     │
│                │  │  Manager     │  │              │
│ - 监控文本     │  │ - 显示下划线  │  │ - AI翻译     │
│ - 获取位置     │  │ - 处理点击   │  │ - 本地模型   │
│ - 追踪窗口     │  │ - 坐标转换   │  │              │
└────────────────┘  └──────────────┘  └──────────────┘
```

### 核心组件

#### 1. AccessibilityMonitor（辅助功能监控器）

**职责：**
- 监控系统中活跃应用的文本输入
- 获取文本在屏幕上的位置
- 追踪窗口移动和调整大小事件

**关键技术点：**
```swift
// 使用 Accessibility API 获取聚焦元素的文本
var focusedElement: AXUIElement?
AXUIElementCopyAttributeValue(element, kAXValueAttribute, &value)

// 获取文本在屏幕上的边界
AXUIElementCopyParameterizedAttributeValue(
    element,
    kAXBoundsForRangeParameterizedAttribute,
    rangeValue,
    &boundsValue
)

// 监听窗口移动事件
AXObserverAddNotification(observer, window, kAXMovedNotification, nil)
```

**双重位置更新机制：**
1. **主要方式**：Accessibility 通知（`kAXMovedNotification`, `kAXResizedNotification`）
2. **备用方式**：定时器轮询（0.1秒间隔），防止通知丢失

#### 2. SpellCheckMonitor（拼写检查监控器）

**职责：**
- 作为系统的核心协调器
- 使用 Combine 订阅文本和位置变化
- 检测中文句子和词组
- 触发 overlay 的显示和更新

**中文检测策略：**
```swift
// 优先级1：检测句子（包含标点符号）
let sentencePattern = "[\\p{Han}][^。！？；，、.!?,;（）()【】\\[\\]「」『』{}\\n]*[。！？；，、.!?,;（）()【】\\[\\]「」『』{}]"

// 优先级2：检测独立词组（2个字以上，不与句子重叠）
let wordPattern = "[\\p{Han}]{2,}"
```

**Combine 响应式编程：**
```swift
// 监听文本变化，500ms 防抖
accessibilityMonitor.$currentText
    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
    .sink { [weak self] text in
        self?.detectChineseText(text)
    }

// 监听窗口位置变化，50ms 快速响应
accessibilityMonitor.$windowPositionChanged
    .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
    .sink { [weak self] _ in
        self?.updateOverlayPositions()
    }
```

#### 3. OverlayWindow（覆盖窗口）

**职责：**
- 创建透明浮动窗口
- 在其他应用上方显示下划线
- 处理用户点击交互
- 显示翻译弹窗

**关键设计：**
```swift
// 窗口配置
self.level = .floating                    // 浮动在所有窗口之上
self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]  // 支持全屏
self.ignoresMouseEvents = false           // 接受鼠标事件
self.canBecomeKey = false                 // 不抢夺焦点
self.canBecomeMain = false

// 窗口覆盖整个文字区域（方便点击）
let clickableRect = NSRect(
    x: rect.origin.x,
    y: rect.origin.y,
    width: rect.width,
    height: rect.height  // 使用文字的完整高度
)
```

**坐标系转换：**
```swift
// Accessibility API 使用顶部左上角为原点
// Cocoa 使用底部左下角为原点
let cocoaY = screenHeight - bounds.origin.y - bounds.size.height
```

**用户体验优化：**
- 鼠标悬停：显示蓝色半透明背景 + 手形指针
- 点击区域：整个文字区域都可点击（不仅仅是下划线）
- 视觉反馈：实时响应鼠标交互

#### 4. SpellService + LocalModelClient（翻译服务）

**职责：**
- 与 Ollama 本地模型通信
- 提供中文到英文的翻译
- 管理翻译缓存

**Ollama 集成：**
```swift
let ollamaClient = Ollama.Client(host: hostURL)
let stream = ollamaClient.generateStream(
    model: modelID,
    prompt: prompt,
    options: [
        "temperature": .double(0.3),
        "top_p": .double(0.9),
        "top_k": .int(40)
    ]
)
```

**配置（OllamaConfig.swift）：**
- 默认模型：`qwen2.5:3b`（轻量级，适合快速翻译）
- 温度：0.3（较低，确保翻译准确性）
- 流式响应：支持逐字返回

## 工作流程

### 1. 启动流程

```
用户打开 Translayr
    ↓
检查 Accessibility 权限
    ↓
启动 AccessibilityMonitor
    ↓
启动 SpellCheckMonitor
    ↓
开始监控系统文本
```

### 2. 文本检测流程

```
用户在其他应用输入文本
    ↓
AccessibilityMonitor 每 0.5 秒检查聚焦元素
    ↓
检测到文本变化 → 发布 currentText
    ↓
SpellCheckMonitor 订阅到变化（500ms 防抖）
    ↓
正则表达式检测中文句子和词组
    ↓
获取每个文本项的屏幕坐标
    ↓
OverlayWindowManager 显示下划线
```

### 3. 窗口移动流程

```
用户移动其他应用窗口
    ↓
方案1: Accessibility 发送 kAXMovedNotification
    ↓
AccessibilityMonitor 接收通知
    ↓
切换 windowPositionChanged 标志
    ↓
SpellCheckMonitor 订阅到变化（50ms 防抖）
    ↓
重新获取所有文本项的屏幕坐标
    ↓
更新所有 overlay 位置
```

```
方案2: 定时器备用方案（每 0.1 秒）
    ↓
checkWindowPosition() 检查窗口位置
    ↓
触发 windowPositionChanged
    ↓
（后续同上）
```

### 4. 翻译流程

```
用户点击下划线
    ↓
UnderlineView.mouseDown 触发
    ↓
调用 onClicked 回调
    ↓
OverlayWindowManager.handleTextClicked
    ↓
SpellCheckMonitor.translateItem
    ↓
SpellService.analyzeWithLocalModelAsync
    ↓
LocalModelClient.translateChineseToEnglish
    ↓
Ollama 生成翻译
    ↓
显示翻译弹窗
    ↓
用户选择翻译 → 替换原文本
```

## 技术亮点

### 1. 无侵入式监控

使用 macOS Accessibility API，无需修改其他应用，即可获取文本内容和位置：

```swift
// 获取活跃应用
let activeApp = NSWorkspace.shared.frontmostApplication
let appElement = AXUIElementCreateApplication(pid)

// 获取聚焦元素
var focusedElement: AnyObject?
AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute, &focusedElement)

// 读取文本
var value: AnyObject?
AXUIElementCopyAttributeValue(element, kAXValueAttribute, &value)
```

### 2. 响应式架构

使用 Combine 框架实现清晰的数据流：

```swift
// 发布者
@Published var currentText: String = ""
@Published var windowPositionChanged: Bool = false

// 订阅者（自动响应变化）
accessibilityMonitor.$currentText
    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
    .sink { text in ... }
```

### 3. 精确的位置追踪

**坐标系统：**
- Accessibility API：顶部左上角为 (0, 0)，Y 向下增长
- Cocoa：底部左下角为 (0, 0)，Y 向上增长

**转换公式：**
```swift
cocoaY = screenHeight - accessibilityY - height
```

### 4. 高性能优化

**防抖机制：**
- 文本检测：500ms 防抖，避免频繁检测
- 位置更新：50ms 防抖，快速响应窗口移动

**窗口复用：**
```swift
// 使用唯一 key 复用 overlay 窗口
let key = "\(range.location)-\(range.length)"
if let window = overlayWindows[key] {
    window.showUnderline(...)  // 复用现有窗口
} else {
    let window = OverlayWindow(...)  // 创建新窗口
    overlayWindows[key] = window
}
```

## 关键文件说明

| 文件 | 职责 | 重要性 |
|------|------|--------|
| **AccessibilityMonitor.swift** | 监控系统文本，获取位置，追踪窗口 | ⭐⭐⭐⭐⭐ |
| **SpellCheckMonitor.swift** | 核心协调器，检测中文，触发更新 | ⭐⭐⭐⭐⭐ |
| **OverlayWindow.swift** | 显示下划线，处理点击，显示弹窗 | ⭐⭐⭐⭐⭐ |
| **SpellService.swift** | 翻译服务，模型调用 | ⭐⭐⭐⭐ |
| **LocalModelClient.swift** | Ollama 集成，AI 翻译 | ⭐⭐⭐⭐ |
| **OllamaConfig.swift** | 模型配置 | ⭐⭐⭐ |
| **ContentView.swift** | 主 UI 视图 | ⭐⭐⭐ |
| **SpellCheckedTextView.swift** | 应用内文本编辑器 | ⭐⭐ |
| **SystemServiceProvider.swift** | 系统服务注册 | ⭐⭐ |
| **Suggestion.swift** | 数据模型 | ⭐ |

## 依赖项

- **macOS 13.0+** - 使用现代 Accessibility API
- **Ollama** - 本地 AI 模型运行时
- **Ollama Swift SDK** - Ollama 客户端库
- **Combine** - 响应式编程框架
- **SwiftUI** - UI 框架

## 权限要求

1. **Accessibility 权限** - 必须授权才能监控其他应用
   - 路径：系统设置 → 隐私与安全性 → 辅助功能
   - 用途：读取其他应用的文本和位置

2. **Ollama 服务** - 需要在本地运行
   ```bash
   # 安装 Ollama
   brew install ollama

   # 启动服务
   ollama serve

   # 下载模型
   ollama pull qwen2.5:3b
   ```

## 常见问题

### Q1: 为什么下划线位置不准确？

可能原因：
1. 应用不支持 Accessibility API 的 `kAXBoundsForRangeParameterizedAttribute`
2. 坐标系转换错误
3. 窗口缩放或多显示器设置

解决方案：检查日志中的坐标信息，验证转换公式。

### Q2: 为什么有些应用无法监控？

某些应用可能：
1. 使用自定义文本渲染，不通过标准 UI 组件
2. 未正确实现 Accessibility 接口
3. 有额外的权限保护

### Q3: 如何优化翻译速度？

1. 使用更小的模型（如 `gemma2:2b`）
2. 调整温度参数降低生成长度
3. 启用流式响应提供即时反馈

## 未来改进方向

1. **缓存优化** - 缓存常用词组的翻译结果
2. **多语言支持** - 支持更多语言对（日语、韩语等）
3. **自定义模型** - 允许用户选择不同的翻译模型
4. **离线词典** - 提供快速查词功能
5. **翻译历史** - 记录翻译历史，支持搜索和复习

## 许可证

MIT License

---

**最后更新：** 2025-10-08
**版本：** 1.0.0
**作者：** eevv

# Translayr 系统级服务使用指南

## 🌟 什么是系统服务？

Translayr 现在提供 **macOS 系统级服务**，允许你在任何支持文本选择的应用中使用 Translayr 的翻译功能，包括：

- **Notes** (备忘录)
- **TextEdit** (文本编辑)
- **Safari** (浏览器)
- **Mail** (邮件)
- **Pages**
- **Xcode**
- 以及其他任何 macOS 应用！

## 🚀 快速开始

### 1. 启动 Translayr 应用

首先运行 Translayr 应用一次，这会注册系统服务：

```bash
# 在 Xcode 中运行，或者
open /path/to/Translayr.app
```

### 2. 刷新系统服务（首次使用）

第一次使用时，需要刷新系统服务缓存：

```bash
# 方法 1: 重启 SystemUIServer（推荐）
killall SystemUIServer

# 方法 2: 注销并重新登录（更彻底）
# System Preferences > Lock Screen > Log Out

# 方法 3: 使用命令行工具
/System/Library/CoreServices/pbs -flush
```

### 3. 开始使用

现在你可以在任何应用中使用 Translayr 服务了！

## 📝 使用方法

### 方法 1: 右键菜单

1. 在任何应用中选择中文文本
2. 右键点击选中的文本
3. 在菜单中找到 **Services** (服务) > **Translayr**
4. 选择你需要的服务：
   - **Translate to English (Translayr)** - 直接翻译替换
   - **Get Translation Suggestions (Translayr)** - 获取多个翻译建议

### 方法 2: 菜单栏

1. 选择文本
2. 点击应用菜单栏
3. 找到 **Services** (或应用名称 > Services)
4. 选择 Translayr 服务

### 方法 3: 键盘快捷键（可选）

你可以为 Translayr 服务设置快捷键：

1. 打开 **System Settings** (系统设置)
2. 进入 **Keyboard** (键盘) > **Keyboard Shortcuts** (键盘快捷键)
3. 选择 **Services** (服务)
4. 找到 **Translayr** 相关服务
5. 点击右侧添加快捷键（建议 `⌘⇧T`）

## 🎯 实际使用示例

### 示例 1: 在 Notes 中翻译

1. 打开 Notes 应用
2. 输入中文：
   ```
   人工智能正在改变世界
   ```
3. 选中文本
4. 右键 > Services > **Translate to English (Translayr)**
5. 文本会被替换为：
   ```
   Artificial intelligence is changing the world
   ```

### 示例 2: 在 TextEdit 中获取建议

1. 打开 TextEdit
2. 输入：
   ```
   机器学习
   ```
3. 选中文本
4. 右键 > Services > **Get Translation Suggestions (Translayr)**
5. 文本会被替换为翻译建议列表：
   ```
   machine learning
   ```

### 示例 3: 在浏览器中使用

1. 在 Safari 的任何网页上选择中文文本
2. 右键 > Services > Translayr
3. 翻译结果会替换选中的文本

## 🔍 验证服务是否已注册

### 检查方法 1: 系统设置

1. 打开 **System Settings** > **Keyboard** > **Keyboard Shortcuts**
2. 点击 **Services** (服务)
3. 滚动查找 **Text** (文本) 分类
4. 应该能看到 Translayr 的服务

### 检查方法 2: 命令行

```bash
# 列出所有已注册的服务
/System/Library/CoreServices/pbs -dump_pboard

# 或查看系统服务数据库
defaults read pbs NSServicesStatus
```

### 检查方法 3: 实际测试

在 TextEdit 中：
1. 输入任意中文文本并选中
2. 右键查看菜单
3. 查看 Services 子菜单

## ⚙️ 配置选项

### 服务名称自定义

编辑 `Info.plist` 中的 `NSMenuItem` 值：

```xml
<key>NSMenuItem</key>
<dict>
    <key>default</key>
    <string>你的自定义名称</string>
</dict>
```

### 快捷键自定义

在 `Info.plist` 中：

```xml
<key>NSKeyEquivalent</key>
<dict>
    <key>default</key>
    <string>T</string>  <!-- ⌘⇧T -->
</dict>
```

修饰键说明：
- 默认包含 `⌘⇧` (Command + Shift)
- 只需指定字母即可

## 🔧 故障排除

### 问题 1: 服务菜单中找不到 Translayr

**解决方案**:

1. 确保 Translayr 应用至少运行过一次
2. 刷新服务缓存：
   ```bash
   killall SystemUIServer
   ```
3. 如果还不行，注销并重新登录

### 问题 2: 服务无响应

**可能原因**:
- Ollama 未运行
- Translayr 应用未在后台运行
- 模型未下载

**解决方案**:
```bash
# 确保 Ollama 运行
ollama serve

# 确保模型已下载
ollama list

# 如果需要，下载模型
ollama pull qwen2.5:3b
```

### 问题 3: 翻译很慢或超时

**解决方案**:
1. 第一次翻译会慢一些（加载模型）
2. 使用更小的模型：`gemma2:2b`
3. 确保 Translayr 应用保持打开状态

### 问题 4: 某些应用不显示服务

**原因**:
某些应用可能不支持系统服务，或者需要特殊权限。

**解决方案**:
- 确认应用支持文本选择和右键菜单
- 某些沙盒应用可能限制服务访问
- 尝试在其他应用中使用

## 💡 高级用法

### 批量翻译

1. 选择多段中文文本（用换行分隔）
2. 使用 **Get Translation Suggestions** 服务
3. 每段会被单独翻译

### 与其他工具结合

可以创建 Automator 工作流，将 Translayr 服务与其他操作结合：

1. 打开 **Automator**
2. 创建新的 **Quick Action** (快速操作)
3. 添加 **Run Service** 操作
4. 选择 Translayr 服务
5. 添加后续操作（如复制到剪贴板）

### 使用 AppleScript 调用

```applescript
tell application "System Events"
    -- 选择文本
    keystroke "a" using command down

    -- 等待
    delay 0.5

    -- 调用服务
    -- (需要通过 UI 脚本实现)
end tell
```

## 📊 性能提示

### 优化响应速度

1. **保持 Translayr 运行**: 不要关闭应用
2. **预热模型**: 启动后先翻译一次
3. **使用轻量模型**: `gemma2:2b` 或 `qwen2.5:3b`
4. **避免大文本**: 分段处理长文本

### 预期性能

| 操作 | 首次 | 后续 |
|------|------|------|
| 服务调用 | 2-3秒 | 1秒 |
| 短文本翻译 | 3-5秒 | 1-2秒 |
| 长文本翻译 | 5-10秒 | 3-5秒 |

## 🎓 最佳实践

1. **保持 Translayr 和 Ollama 运行**: 获得最佳性能
2. **先测试小文本**: 确保服务正常工作
3. **设置快捷键**: 提高使用效率
4. **定期更新模型**: 获得更好的翻译质量
5. **使用建议服务**: 对于重要翻译，先查看建议再决定

## 🔐 隐私和安全

### 数据处理

- ✅ 所有翻译在本地完成
- ✅ 不会发送数据到云端
- ✅ Ollama 完全离线运行
- ✅ 符合 macOS 沙盒安全要求

### 权限要求

Translayr 需要以下权限：
- **网络客户端**: 连接本地 Ollama (127.0.0.1)
- **读取选中文本**: 从其他应用获取文本
- **写入文本**: 替换翻译结果

所有权限都在沙盒内，不会访问系统敏感数据。

## 📚 技术细节

### NSServices 实现

Translayr 使用 macOS NSServices 框架实现系统级服务：

- **服务提供者**: `SystemServiceProvider` 类
- **服务方法**:
  - `translateToEnglish(_:userData:error:)`
  - `getTranslationSuggestions(_:userData:error:)`
- **数据传递**: 通过 NSPasteboard (剪贴板)
- **异步处理**: 使用 Swift Concurrency (async/await)

### 工作流程

```
用户选择文本
    ↓
系统调用服务
    ↓
Translayr 从 Pasteboard 读取文本
    ↓
Ollama 进行翻译
    ↓
结果写回 Pasteboard
    ↓
系统替换原文本
```

## 🆘 获取帮助

如果遇到问题：

1. 查看 Translayr 应用的控制台输出（调试信息）
2. 检查系统日志：Console.app > 搜索 "Translayr"
3. 参考 README.md 和 USAGE.md
4. 创建 GitHub Issue

## 🎉 享受使用！

现在你可以在整个 macOS 系统中使用 Translayr 的翻译功能了！

试试在不同的应用中选择中文文本，体验无缝的翻译体验吧！

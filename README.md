# Spello - macOS拼写检查应用

一个为macOS设计的本地拼写检查应用，支持实时拼写检查和智能文本分析。

## 功能特性

### 核心功能
- **实时拼写检查**: 基于NSTextView的实时红色下划线标记
- **统一检查模式**: 点击"检查"按钮进行全文拼写检查
- **智能建议**: 结合系统拼写检查器和本地AI模型
- **多语言支持**: 支持英语、西班牙语、法语、德语等多种语言
- **用户词典**: 支持添加自定义词汇和忽略特定单词

### 技术特性
- **SwiftUI + AppKit**: 现代化的macOS原生界面
- **NSSpellChecker集成**: 充分利用macOS系统拼写检查能力
- **本地AI模型支持**: 可选接入本地Ollama模型进行高级语法检查
- **模块化架构**: 易于扩展和维护

## 系统要求

- macOS 13.0 或更高版本
- Xcode 14.0 或更高版本（用于开发）

## 安装和运行

### 1. 克隆项目
```bash
git clone <repository-url>
cd Spello
```

### 2. 打开项目
```bash
open Spello.xcodeproj
```

### 3. 编译和运行
在Xcode中选择目标设备并点击运行按钮，或使用快捷键 `Cmd+R`。

## 使用说明

### 基本操作

1. **启动应用**: 打开Spello后，您会看到一个文本编辑界面
2. **输入文本**: 在文本区域输入或粘贴您要检查的文本
3. **实时检查**: 拼写错误会自动用红色下划线标记
4. **右键菜单**: 右键点击错误单词查看建议和操作选项
5. **统一检查**: 点击"检查拼写"按钮获得完整的错误列表

### 工具栏功能

- **检查拼写**: 扫描全文并显示所有拼写问题
- **自动更正**: 开启/关闭自动拼写更正
- **AI建议**: 启用/禁用本地AI模型建议
- **语言选择**: 选择特定语言或使用自动检测

### 建议面板

点击"检查拼写"后会打开建议面板，包含：

- **错误列表**: 按出现顺序显示所有拼写错误
- **上下文显示**: 显示错误单词的周围文本
- **建议候选**: 提供多个替换选项
- **来源标识**: 区分系统建议和AI模型建议
- **快速操作**:
  - 点击候选词直接替换
  - "忽略"按钮忽略当前文档中的该词
  - "添加到词典"将词汇加入系统词典

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

## 本地AI模型集成

### Ollama集成示例

如果您想使用本地Ollama模型进行高级语法检查：

1. **安装Ollama**:
```bash
curl -fsSL https://ollama.ai/install.sh | sh
```

2. **下载语言模型**:
```bash
ollama pull llama2
# 或其他适合的模型
```

3. **启动服务**:
```bash
ollama serve
```

4. **配置应用**: 在应用中启用"AI建议"开关

### HTTP API格式

本地模型客户端期望的API格式：

```json
POST http://127.0.0.1:8080/analyze

请求体:
{
  "text": "要检查的文本",
  "language": "en_US",
  "task": "spell_check"
}

响应:
{
  "suggestions": [
    {
      "word": "错误单词",
      "start": 10,
      "length": 5,
      "candidates": ["建议1", "建议2"],
      "confidence": 0.95
    }
  ]
}
```

## 开发指南

### 核心组件

1. **SpellService**: 负责协调系统拼写检查和本地模型
2. **SpellCheckedTextView**: NSViewRepresentable包装的NSTextView
3. **SuggestionsView**: 显示检查结果的SwiftUI视图
4. **LocalModelClient**: 处理与本地AI模型的通信

### 扩展建议

- 添加更多语言支持
- 实现语法检查功能
- 添加写作风格建议
- 支持多种文档格式
- 添加性能优化

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

## 性能考虑

- 大文本处理使用后台队列避免UI阻塞
- 实时检查只处理当前可见区域
- 建议缓存减少重复计算
- 异步处理本地模型请求

## 许可证

MIT License - 详见LICENSE文件

## 贡献

欢迎提交Issue和Pull Request来改进项目。

## 支持

如有问题或建议，请创建GitHub Issue。
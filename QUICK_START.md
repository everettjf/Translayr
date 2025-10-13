# Translayr Release - Quick Start Guide

快速上手指南 - 5 分钟配置，一键发布

## 📦 已创建的文件

```
Translayr/
├── scripts/
│   ├── build-release.sh         # 🚀 一键构建发布版本
│   └── sign-and-notarize.sh     # ✍️  单独签名和公证工具
├── .env.template                 # 🔑 配置模板
├── ExportOptions.plist           # ⚙️  Xcode 导出配置
├── BUILD_RELEASE.md              # 📖 完整发布指南
└── QUICK_START.md                # ⚡ 快速开始（本文件）
```

## ⚡ 快速开始 (3 步)

### 1️⃣ 配置凭证 (仅首次)

```bash
# 复制配置模板
cp .env.template .env

# 编辑配置文件
nano .env  # 填入你的 Apple Developer 凭证
```

**需要的信息：**
- **Developer ID 证书名称** - 从 Keychain Access 复制
- **Apple ID 邮箱**
- **Team ID** (10字符) - 从 developer.apple.com 获取
- **App-specific password** - 从 appleid.apple.com 生成

> 💡 详细获取方法见 `.env.template` 文件中的注释

### 2️⃣ 更新 GitHub 仓库信息

编辑 `Translayr/Services/UpdateChecker.swift:14-15`：

```swift
private let githubOwner = "your-github-username"  // 改为你的 GitHub 用户名
private let githubRepo = "Translayr"              // 你的仓库名
```

### 3️⃣ 一键构建

```bash
# 构建 1.0.0 版本
./scripts/build-release.sh 1.0.0
```

**脚本会自动完成：**
- ✅ 清理构建目录
- ✅ 更新版本号
- ✅ 构建 Archive
- ✅ 导出 App
- ✅ 代码签名
- ✅ 创建 DMG
- ✅ 上传公证
- ✅ 装订票据

**构建时间：** 约 5-15 分钟

**输出文件：** `build/Translayr-1.0.0.dmg`

---

## 🎯 发布流程

### 测试 DMG
在干净的 Mac 上测试下载和安装：
```bash
# 打开构建目录
open build/

# 测试安装 DMG
```

### 创建 GitHub Release

1. 访问仓库的 Releases 页面
2. 点击 "Create a new release"
3. Tag: `v1.0.0`
4. 上传 `Translayr-1.0.0.dmg`
5. 发布！

**用户下载后：**
- 应用会自动检测更新 ✅
- 菜单栏显示更新提示 ✅
- 点击跳转到下载页面 ✅

---

## 🔧 常用命令

### 完整构建（推荐）
```bash
./scripts/build-release.sh 1.0.0
```

### 仅签名现有 App
```bash
./scripts/sign-and-notarize.sh build/export/Translayr.app
```

### 仅公证现有 DMG
```bash
./scripts/sign-and-notarize.sh build/Translayr-1.0.0.dmg
```

### 检查代码签名
```bash
codesign -vvv --deep --strict build/export/Translayr.app
```

### 验证公证
```bash
xcrun stapler validate build/Translayr-1.0.0.dmg
```

---

## 🚨 首次使用检查清单

- [ ] 已安装 Xcode Command Line Tools
- [ ] 已安装 Homebrew
- [ ] 已安装 create-dmg (`brew install create-dmg`)
- [ ] 已有 Apple Developer 账号（付费）
- [ ] 已下载并安装 Developer ID 证书
- [ ] 已创建 `.env` 文件并填写凭证
- [ ] 已更新 `UpdateChecker.swift` 中的 GitHub 信息
- [ ] 脚本已添加执行权限

---

## 📚 需要更多帮助？

**详细指南：** 查看 `BUILD_RELEASE.md`
- 前置要求详解
- 分步骤手动构建
- 完整的故障排除
- GitHub Actions 自动化

**问题排查：**
```bash
# 检查证书
security find-identity -v -p codesigning

# 检查 Xcode
xcode-select -p

# 测试环境变量
source .env && echo $DEVELOPER_ID_APPLICATION
```

---

## 🎉 第一次发布后

1. **测试更新功能**
   - 运行旧版本应用
   - 检查是否检测到新版本
   - 验证下载链接正确

2. **添加 Homebrew Cask**（可选）
   ```ruby
   cask "translayr" do
     version "1.0.0"
     url "https://github.com/username/Translayr/releases/download/v1.0.0/Translayr-1.0.0.dmg"
     name "Translayr"
     homepage "https://github.com/username/Translayr"
     app "Translayr.app"
   end
   ```

3. **设置 GitHub Actions**（可选）
   - 自动化发布流程
   - 参考 `BUILD_RELEASE.md` 中的配置

---

## 💡 提示

- 🔐 **永远不要提交 `.env` 到 Git** (已在 .gitignore 中)
- 📝 使用语义化版本号：`major.minor.patch`
- 🧪 发布前在干净的 Mac 上测试 DMG
- 📊 考虑集成 TelemetryDeck 或 Mixpanel 统计用户数
- 🐛 考虑集成 Sentry 收集崩溃报告

---

## 下一步

1. ✅ 完成首次配置
2. ✅ 构建并测试第一个版本
3. ✅ 发布到 GitHub Releases
4. 📈 添加统计和错误追踪
5. 🤖 设置 GitHub Actions 自动化

**准备好了吗？开始构建你的第一个发布版本：**
```bash
./scripts/build-release.sh 1.0.0
```

---

**祝发布顺利！** 🚀

# Translayr Release Build Guide

完整的 macOS 应用签名、公证和发布指南。

## 目录

- [前置要求](#前置要求)
- [首次配置](#首次配置)
- [构建发布版本](#构建发布版本)
- [手动签名和公证](#手动签名和公证)
- [发布到 GitHub](#发布到-github)
- [故障排除](#故障排除)

---

## 前置要求

### 1. Apple Developer 账号

- 需要付费的 Apple Developer Program 会员资格（$99/年）
- 注册地址：https://developer.apple.com/programs/

### 2. Developer ID 证书

1. 访问 [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. 点击 "+" 创建新证书
3. 选择 "Developer ID Application"（用于在 Mac App Store 外分发）
4. 跟随指示创建 CSR (Certificate Signing Request)
5. 下载证书并双击安装到 Keychain

**验证证书：**
```bash
security find-identity -v -p codesigning
```

应该看到类似：
```
1) ABC1234567 "Developer ID Application: Your Name (TEAM_ID)"
```

### 3. 必需的工具

#### Xcode Command Line Tools
```bash
xcode-select --install
```

#### Homebrew (如果还没安装)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### create-dmg (用于创建 DMG)
```bash
brew install create-dmg
```

#### xcpretty (可选，美化输出)
```bash
gem install xcpretty
```

---

## 首次配置

### 步骤 1: 配置环境变量

1. 复制配置模板：
```bash
cd /path/to/Translayr
cp .env.template .env
```

2. 编辑 `.env` 文件，填入你的凭证：
```bash
nano .env  # 或使用你喜欢的编辑器
```

需要填写的信息：

#### a. DEVELOPER_ID_APPLICATION
打开 Keychain Access → My Certificates，找到 "Developer ID Application" 证书，复制完整名称：
```
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (ABC1234567)"
```

#### b. APPLE_ID
你的 Apple ID 邮箱：
```
APPLE_ID="your-email@example.com"
```

#### c. TEAM_ID
访问 https://developer.apple.com/account → Membership，找到 Team ID（10个字符）：
```
TEAM_ID="ABC1234567"
```

#### d. APPLE_APP_PASSWORD
**重要：** 这不是你的 Apple ID 密码！

1. 访问 https://appleid.apple.com/account/manage
2. 在 "Security" 部分，点击 "App-Specific Passwords"
3. 点击 "Generate Password"
4. 输入标签名（例如：Translayr Notarization）
5. 复制生成的密码（格式：xxxx-xxxx-xxxx-xxxx）

```
APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

### 步骤 2: 测试配置

```bash
# 加载环境变量
source .env

# 测试证书
security find-identity -v -p codesigning | grep "$TEAM_ID"

# 测试公证凭证（可选，不会提交任何内容）
xcrun notarytool store-credentials "test-profile" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APPLE_APP_PASSWORD"
```

### 步骤 3: 更新 UpdateChecker.swift

编辑 `Translayr/Services/UpdateChecker.swift`，修改 GitHub 仓库信息：

```swift
private let githubOwner = "your-github-username"
private let githubRepo = "Translayr"
```

### 步骤 4: 添加执行权限

```bash
chmod +x scripts/build-release.sh
chmod +x scripts/sign-and-notarize.sh
```

---

## 构建发布版本

### 自动化构建（推荐）

一键完成所有步骤（构建、签名、公证、打包）：

```bash
./scripts/build-release.sh 1.0.0
```

脚本会自动：
1. ✅ 清理构建目录
2. ✅ 更新 Info.plist 版本号
3. ✅ 构建 Xcode Archive
4. ✅ 导出 .app
5. ✅ 代码签名
6. ✅ 创建 DMG
7. ✅ 上传到 Apple 公证
8. ✅ 装订公证票据

**预计耗时：** 5-15 分钟（公证需要等待 Apple 处理）

构建完成后，DMG 文件位于：
```
build/Translayr-1.0.0.dmg
```

### 手动构建步骤

如果需要更多控制，可以手动执行各个步骤：

#### 1. 构建 Archive
```bash
xcodebuild archive \
  -scheme Translayr \
  -configuration Release \
  -archivePath build/Translayr.xcarchive \
  CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)" \
  -allowProvisioningUpdates
```

#### 2. 导出 App
```bash
xcodebuild -exportArchive \
  -archivePath build/Translayr.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

#### 3. 签名
```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --timestamp \
  build/export/Translayr.app
```

#### 4. 创建 DMG
```bash
create-dmg \
  --volname "Translayr" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 450 200 \
  build/Translayr-1.0.0.dmg \
  build/export/Translayr.app
```

#### 5. 公证
```bash
xcrun notarytool submit build/Translayr-1.0.0.dmg \
  --apple-id "your-email@example.com" \
  --team-id "TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  --wait
```

#### 6. 装订票据
```bash
xcrun stapler staple build/Translayr-1.0.0.dmg
```

---

## 手动签名和公证

如果你已经有了 .app 或 .dmg 文件，可以使用独立的签名脚本：

### 对 .app 签名并创建 DMG
```bash
./scripts/sign-and-notarize.sh build/export/Translayr.app
```

### 对现有 DMG 公证
```bash
./scripts/sign-and-notarize.sh build/Translayr-1.0.0.dmg
```

---

## 发布到 GitHub

### 步骤 1: 测试 DMG

在**另一台干净的 Mac**（或新用户账户）上测试：

1. 下载 DMG
2. 打开 DMG
3. 拖拽 Translayr.app 到 Applications
4. 从 Applications 运行应用
5. 验证不会出现 "已损坏" 或 "来自身份不明开发者" 的警告

### 步骤 2: 创建 GitHub Release

#### 方法 1: 使用 GitHub 网页界面

1. 访问你的仓库页面
2. 点击 "Releases" → "Create a new release"
3. 填写 Release 信息：

**Tag version:** `v1.0.0`
**Release title:** `Translayr 1.0.0`
**Description:**
```markdown
## What's New

- Added automatic update checking
- Improved translation accuracy
- Bug fixes and performance improvements

## Installation

1. Download `Translayr-1.0.0.dmg` below
2. Open the DMG file
3. Drag Translayr to your Applications folder
4. Launch from Applications

## System Requirements

- macOS 12.0 or later
- Accessibility permissions required for text monitoring

## Known Issues

- First launch may take a few seconds
- Some apps need to be restarted for Translayr to work

---

**Full Changelog**: https://github.com/username/Translayr/compare/v0.9.0...v1.0.0
```

4. 上传 `Translayr-1.0.0.dmg`
5. 点击 "Publish release"

#### 方法 2: 使用 GitHub CLI

```bash
# 安装 gh CLI
brew install gh

# 登录
gh auth login

# 创建 release
gh release create v1.0.0 \
  build/Translayr-1.0.0.dmg \
  --title "Translayr 1.0.0" \
  --notes "See full release notes at https://github.com/username/Translayr/releases/tag/v1.0.0"
```

### 步骤 3: 验证自动更新

1. 运行你的应用（旧版本）
2. 应该会自动检测到新版本
3. 点击更新通知
4. 确认能正确打开 GitHub Releases 页面

---

## 故障排除

### 问题：签名失败 "no identity found"

**解决方案：**
```bash
# 检查可用的签名身份
security find-identity -v -p codesigning

# 如果没有找到，重新安装证书
# 1. 从 developer.apple.com 下载证书
# 2. 双击 .cer 文件安装到 Keychain
```

### 问题：公证失败 "Invalid credentials"

**检查：**
1. Apple ID 是否正确
2. 是否使用了 App-specific password（不是普通密码）
3. Team ID 是否正确

**重新生成 App-specific password：**
1. https://appleid.apple.com/account/manage
2. Security → App-Specific Passwords
3. 生成新密码并更新 .env

### 问题：公证失败 "The binary is not signed"

**解决方案：**
确保在公证前进行了签名，并且使用了 `--options runtime` 标志：
```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --timestamp \
  Translayr.app
```

### 问题：用户打开 DMG 后显示"已损坏"

**原因：** 应用未公证或公证票据未装订

**解决方案：**
1. 确保公证成功
2. 运行 `xcrun stapler staple Translayr.dmg`
3. 验证：`xcrun stapler validate Translayr.dmg`

### 问题：构建时找不到 Xcode

**解决方案：**
```bash
# 设置 Xcode 路径
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# 验证
xcode-select -p
```

### 问题：create-dmg 命令未找到

**解决方案：**
```bash
brew install create-dmg
```

### 问题：UpdateChecker 无法检测到新版本

**检查：**
1. `UpdateChecker.swift` 中的 GitHub 用户名和仓库名是否正确
2. GitHub Release 的 tag 格式是否为 `v1.0.0`（带 v 前缀）
3. Release 是否为正式版本（不是 prerelease）
4. 网络连接是否正常

---

## 版本号管理

遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范：

- **主版本号 (Major)**: 不兼容的 API 变更
- **次版本号 (Minor)**: 向下兼容的功能新增
- **修订号 (Patch)**: 向下兼容的问题修复

示例：
- `1.0.0` - 首个正式版本
- `1.1.0` - 添加新功能
- `1.1.1` - 修复 bug
- `2.0.0` - 重大更新

---

## 自动化发布流程（高级）

### 使用 GitHub Actions

创建 `.github/workflows/release.yml`：

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup environment
        env:
          DEVELOPER_ID_APPLICATION: ${{ secrets.DEVELOPER_ID_APPLICATION }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          TEAM_ID: ${{ secrets.TEAM_ID }}
          APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
        run: |
          echo "DEVELOPER_ID_APPLICATION=$DEVELOPER_ID_APPLICATION" > .env
          echo "APPLE_ID=$APPLE_ID" >> .env
          echo "TEAM_ID=$TEAM_ID" >> .env
          echo "APPLE_APP_PASSWORD=$APPLE_APP_PASSWORD" >> .env

      - name: Build release
        run: |
          chmod +x scripts/build-release.sh
          ./scripts/build-release.sh ${GITHUB_REF#refs/tags/v}

      - name: Upload to release
        uses: softprops/action-gh-release@v1
        with:
          files: build/*.dmg
```

**配置 GitHub Secrets：**
1. 进入仓库 Settings → Secrets → Actions
2. 添加以下 secrets：
   - `DEVELOPER_ID_APPLICATION`
   - `APPLE_ID`
   - `TEAM_ID`
   - `APPLE_APP_PASSWORD`

---

## 其他发布渠道

### Homebrew Cask

提交到 Homebrew 让用户可以通过 `brew install --cask translayr` 安装：

1. Fork https://github.com/Homebrew/homebrew-cask
2. 创建 Cask 文件：`Casks/translayr.rb`
3. 提交 Pull Request

### Setapp

如果想通过订阅平台分发：
- 申请加入：https://setapp.com/developers
- 好处：处理付费、更新、统计

---

## 相关资源

- [Apple 公证指南](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [代码签名指南](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [create-dmg 文档](https://github.com/create-dmg/create-dmg)
- [语义化版本](https://semver.org/lang/zh-CN/)

---

## 支持

如果遇到问题：
1. 查看上面的"故障排除"部分
2. 检查脚本输出的详细错误信息
3. 在 GitHub 提交 Issue

---

**最后更新：** 2025-01-12

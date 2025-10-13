#!/bin/bash
#
# build-release.sh
# 完整的构建、签名、公证、打包流程
#
# 使用方法:
#   ./scripts/build-release.sh 1.0.0
#

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 检查参数
if [ $# -eq 0 ]; then
    error "Usage: $0 <version>\nExample: $0 1.0.0"
fi

VERSION=$1
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/Translayr.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP_NAME="Translayr"
APP_PATH="$EXPORT_DIR/$APP_NAME.app"

info "Building Translayr version $VERSION"
info "Project root: $PROJECT_ROOT"

# 加载环境变量
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
    success "Loaded configuration from .env"
else
    error "Configuration file .env not found!\nPlease copy .env.template to .env and fill in your credentials."
fi

# 检查必要的环境变量
if [ -z "$DEVELOPER_ID_APPLICATION" ]; then
    error "DEVELOPER_ID_APPLICATION not set in .env"
fi

if [ -z "$APPLE_ID" ]; then
    error "APPLE_ID not set in .env"
fi

if [ -z "$TEAM_ID" ]; then
    error "TEAM_ID not set in .env"
fi

# 步骤 1: 清理旧的构建文件
info "Step 1/7: Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$EXPORT_DIR"
success "Build directory cleaned"

# 步骤 2: 更新版本号
info "Step 2/7: Updating version number to $VERSION..."
PLIST_PATH="$PROJECT_ROOT/Translayr/Info.plist"

if [ ! -f "$PLIST_PATH" ]; then
    error "Info.plist not found at $PLIST_PATH"
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST_PATH"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST_PATH"
success "Version updated to $VERSION"

# 步骤 3: 构建 Archive
info "Step 3/7: Building archive..."
cd "$PROJECT_ROOT"

xcodebuild archive \
    -scheme Translayr \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    -allowProvisioningUpdates \
    | xcpretty || error "Archive build failed"

success "Archive created at $ARCHIVE_PATH"

# 步骤 4: 导出 App
info "Step 4/7: Exporting application..."

# 检查 ExportOptions.plist 是否存在
EXPORT_OPTIONS="$PROJECT_ROOT/ExportOptions.plist"
if [ ! -f "$EXPORT_OPTIONS" ]; then
    error "ExportOptions.plist not found at $EXPORT_OPTIONS"
fi

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    | xcpretty || error "Export failed"

success "Application exported to $EXPORT_DIR"

# 步骤 5: 签名
info "Step 5/7: Signing application..."

codesign --deep --force --verify --verbose \
    --sign "$DEVELOPER_ID_APPLICATION" \
    --options runtime \
    --timestamp \
    "$APP_PATH" || error "Code signing failed"

# 验证签名
codesign --verify --deep --strict --verbose=2 "$APP_PATH" || error "Code signature verification failed"
spctl --assess --type execute --verbose=4 "$APP_PATH" || warning "Gatekeeper assessment shows warnings (this is expected before notarization)"

success "Application signed successfully"

# 步骤 6: 创建 DMG
info "Step 6/7: Creating DMG..."

DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

# 检查是否安装了 create-dmg
if ! command -v create-dmg &> /dev/null; then
    warning "create-dmg not found, installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install create-dmg
    else
        error "Homebrew not found. Please install create-dmg manually:\nbrew install create-dmg"
    fi
fi

# 创建 DMG
create-dmg \
    --volname "$APP_NAME" \
    --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 150 200 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 450 200 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH" || error "DMG creation failed"

success "DMG created at $DMG_PATH"

# 步骤 7: 公证
info "Step 7/7: Notarizing application..."

# 上传公证
info "Uploading to Apple for notarization (this may take a few minutes)..."

NOTARIZE_OUTPUT=$(xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait 2>&1)

echo "$NOTARIZE_OUTPUT"

# 检查公证是否成功
if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
    success "Notarization succeeded"

    # 装订票据
    info "Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH" || error "Stapling failed"

    # 验证装订
    xcrun stapler validate "$DMG_PATH" || error "Staple validation failed"

    success "Ticket stapled successfully"
else
    error "Notarization failed. Check the output above for details."
fi

# 最终验证
info "Performing final verification..."
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"

# 完成
echo ""
success "🎉 Release build completed successfully!"
echo ""
info "Release package: $DMG_PATH"
info "Size: $(du -h "$DMG_PATH" | cut -f1)"
info "Version: $VERSION"
echo ""
info "Next steps:"
echo "  1. Test the DMG on a clean Mac"
echo "  2. Create a GitHub release (tag: v$VERSION)"
echo "  3. Upload $DMG_NAME to the release"
echo "  4. Update release notes"
echo ""

# 可选：自动打开 Finder
if command -v open &> /dev/null; then
    open "$BUILD_DIR"
fi

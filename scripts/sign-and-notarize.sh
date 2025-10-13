#!/bin/bash
#
# sign-and-notarize.sh
# 单独对已有的 .app 或 .dmg 进行签名和公证
#
# 使用方法:
#   ./scripts/sign-and-notarize.sh /path/to/Translayr.app
#   ./scripts/sign-and-notarize.sh /path/to/Translayr.dmg
#

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# 检查参数
if [ $# -eq 0 ]; then
    error "Usage: $0 <path-to-app-or-dmg>\nExample: $0 build/export/Translayr.app"
fi

TARGET_PATH="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 检查文件是否存在
if [ ! -e "$TARGET_PATH" ]; then
    error "File not found: $TARGET_PATH"
fi

# 判断是 .app 还是 .dmg
if [[ "$TARGET_PATH" == *.app ]]; then
    FILE_TYPE="app"
    info "Detected: macOS Application Bundle"
elif [[ "$TARGET_PATH" == *.dmg ]]; then
    FILE_TYPE="dmg"
    info "Detected: Disk Image"
else
    error "Unsupported file type. Please provide .app or .dmg"
fi

# 加载环境变量
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
    success "Loaded configuration"
else
    error ".env file not found"
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

# 如果是 .app，先签名
if [ "$FILE_TYPE" == "app" ]; then
    info "Signing application..."

    codesign --deep --force --verify --verbose \
        --sign "$DEVELOPER_ID_APPLICATION" \
        --options runtime \
        --timestamp \
        "$TARGET_PATH" || error "Signing failed"

    # 验证签名
    codesign --verify --deep --strict --verbose=2 "$TARGET_PATH" || error "Signature verification failed"

    success "Application signed"

    # 询问是否创建 DMG
    echo ""
    read -p "Do you want to create a DMG? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DMG_PATH="${TARGET_PATH%.*}.dmg"
        info "Creating DMG at $DMG_PATH..."

        if ! command -v create-dmg &> /dev/null; then
            warning "create-dmg not installed. Installing via Homebrew..."
            brew install create-dmg || error "Failed to install create-dmg"
        fi

        create-dmg \
            --volname "Translayr" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --app-drop-link 450 200 \
            "$DMG_PATH" \
            "$TARGET_PATH" || error "DMG creation failed"

        success "DMG created: $DMG_PATH"
        TARGET_PATH="$DMG_PATH"
    else
        info "Skipping DMG creation"
        echo ""
        success "Signing completed. Run this script again with the DMG to notarize."
        exit 0
    fi
fi

# 公证
info "Starting notarization..."
info "Uploading to Apple (this may take several minutes)..."

NOTARIZE_OUTPUT=$(xcrun notarytool submit "$TARGET_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait 2>&1)

echo "$NOTARIZE_OUTPUT"

# 检查公证结果
if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
    success "Notarization succeeded"

    # 装订票据
    info "Stapling notarization ticket..."
    xcrun stapler staple "$TARGET_PATH" || error "Stapling failed"

    # 验证
    xcrun stapler validate "$TARGET_PATH" || error "Validation failed"

    success "Ticket stapled successfully"
else
    error "Notarization failed. Check output above."
fi

# 最终验证
info "Performing final Gatekeeper check..."
spctl --assess --type open --context context:primary-signature --verbose=4 "$TARGET_PATH"

echo ""
success "🎉 Signing and notarization completed!"
info "File: $TARGET_PATH"
echo ""

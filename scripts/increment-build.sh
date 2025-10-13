#!/bin/bash
#
# increment-build.sh
# 递增 Build Number (CFBundleVersion)
#
# 使用方法:
#   ./scripts/increment-build.sh
#

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_PATH="$PROJECT_ROOT/Translayr/Info.plist"

# 检查 Info.plist 是否存在
if [ ! -f "$PLIST_PATH" ]; then
    echo -e "${RED}❌ Info.plist not found at $PLIST_PATH${NC}"
    exit 1
fi

# 获取当前 Build Number
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST_PATH" 2>/dev/null || echo "0")

# 如果是空字符串或非数字，设置为 0
if [ -z "$CURRENT_BUILD" ] || ! [[ "$CURRENT_BUILD" =~ ^[0-9]+$ ]]; then
    echo -e "${BLUE}ℹ️  Current build is empty or invalid, starting from 0${NC}"
    CURRENT_BUILD=0
fi

# 递增 Build Number
NEW_BUILD=$((CURRENT_BUILD + 1))

# 更新 Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$PLIST_PATH"

echo -e "${BLUE}ℹ️  Build Number:${NC} $CURRENT_BUILD → ${GREEN}$NEW_BUILD${NC}"
echo -e "${GREEN}✅ Build number incremented successfully${NC}"

#!/bin/bash
#
# increment-version.sh
# 递增 Version 的最后一位 (CFBundleShortVersionString)
#
# 使用方法:
#   ./scripts/increment-version.sh
#
# 示例:
#   1.0.0 → 1.0.1
#   1.2.5 → 1.2.6
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

# 获取当前 Version
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST_PATH")

# 分割版本号
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"

# 确保有足够的部分
if [ ${#VERSION_PARTS[@]} -lt 1 ]; then
    echo -e "${RED}❌ Invalid version format: $CURRENT_VERSION${NC}"
    exit 1
fi

# 递增最后一位
LAST_INDEX=$((${#VERSION_PARTS[@]} - 1))
VERSION_PARTS[$LAST_INDEX]=$((${VERSION_PARTS[$LAST_INDEX]} + 1))

# 重新组合版本号
NEW_VERSION=$(IFS='.'; echo "${VERSION_PARTS[*]}")

# 更新 Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$PLIST_PATH"

echo -e "${BLUE}ℹ️  Version:${NC} $CURRENT_VERSION → ${GREEN}$NEW_VERSION${NC}"
echo -e "${GREEN}✅ Version incremented successfully${NC}"

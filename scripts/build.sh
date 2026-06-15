#!/bin/bash
# APK Builder - 编译并输出到 F 盘
# 用法: build.sh <项目路径>

set -e

PROJECT_DIR="${1:-.}"
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

export JAVA_HOME="${JAVA_HOME:-D:/Android_studio/jbr}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/AppData/Local/Android/Sdk}"

# POSIX 路径
if echo "$JAVA_HOME" | grep -q "^[A-Za-z]:"; then
    JAVA_HOME=$(echo "$JAVA_HOME" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/\L\1|')
fi
export PATH="$JAVA_HOME/bin:$PATH"

# 检查环境
if [ ! -f "$JAVA_HOME/bin/java" ] && [ ! -f "$JAVA_HOME/bin/java.exe" ]; then
    echo "[ERROR] JDK 未找到: $JAVA_HOME"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/gradlew" ]; then
    echo "[ERROR] 未找到 gradlew"
    exit 1
fi

# 获取应用名
APP_NAME=$(grep "rootProject.name" "$PROJECT_DIR/settings.gradle" 2>/dev/null | sed "s/.*'\\(.*\\)'.*/\\1/" || echo "app")

echo "[1/3] 清理缓存"
rm -rf "$PROJECT_DIR/app/build" "$PROJECT_DIR/build"

echo "[2/3] 编译 APK"
cd "$PROJECT_DIR"
./gradlew assembleDebug --no-daemon 2>&1

APK_PATH="$PROJECT_DIR/app/build/outputs/apk/debug/app-debug.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "[ERROR] 编译失败"
    exit 1
fi

SIZE=$(du -h "$APK_PATH" | cut -f1)
echo ""
echo "[3/3] 输出到 F 盘"
cp "$APK_PATH" "/f/${APP_NAME}.apk"
echo ""
echo "=========================================="
echo "  编译成功!"
echo "  APK: F:\\${APP_NAME}.apk ($SIZE)"
echo "=========================================="

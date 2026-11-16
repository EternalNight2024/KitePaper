#!/usr/bin/env bash
# ============================================================================
# 构建 Android 产物（Release）
# 用途: 本地开发或 CI 调用
# 输出:
#   build/app/outputs/flutter-apk/app-release.apk
#   build/app/outputs/bundle/release/app-release.aab
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "[ERROR] Flutter 未找到，请确保已安装并加入 PATH" >&2
  exit 1
fi

echo "[1/4] 获取依赖..."
flutter pub get

echo "[2/4] 静态分析..."
flutter analyze lib test

echo "[3/4] 运行单元测试..."
flutter test

echo "[4/4] 构建 Android Release (APK + AAB)..."
flutter build apk --release
flutter build appbundle --release

echo "[DONE] Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "[DONE] Android AAB: build/app/outputs/bundle/release/app-release.aab"

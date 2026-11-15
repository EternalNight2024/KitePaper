#!/usr/bin/env bash
# ============================================================================
# 构建 Windows 产物（Release）
# 用途: 本地开发或 CI 调用
# 输出: build/windows/x64/runner/Release/kitepaper.zip
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

echo "[2/4] 静态分析（非阻断）..."
flutter analyze lib test || true

echo "[3/4] 运行单元测试（非阻断）..."
flutter test || true

echo "[4/4] 构建 Windows Release..."
flutter build windows --release

ZIP_PATH="build/windows/x64/runner/Release/kitepaper.zip"
if [ ! -f "$ZIP_PATH" ]; then
  echo "[WARN] 未检测到预期的 zip 路径 $ZIP_PATH，尝试查找..."
  find build/windows -name "*.zip" -o -name "kitepaper.exe" 2>/dev/null || true
  exit 1
fi

echo "[DONE] Windows 产物: $ZIP_PATH"

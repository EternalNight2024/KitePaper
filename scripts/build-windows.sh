#!/usr/bin/env bash
# ============================================================================
# 构建 Windows Release 产物并打包为 zip（本地开发 / CI 通用）
# 输出: build/windows/kitepaper.zip
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

echo "[4/4] 构建 Windows Release..."
flutter build windows --release

RELEASE_DIR="$ROOT/build/windows/x64/runner/Release"
if [ ! -d "$RELEASE_DIR" ]; then
  echo "[ERROR] 未找到 Windows 构建输出目录：$RELEASE_DIR" >&2
  exit 1
fi

ZIP_PATH="$ROOT/build/windows/kitepaper.zip"
rm -f "$ZIP_PATH"

# Linux/macOS 用 zip；Windows runner 在没有 zip 时回退到 PowerShell。
if command -v zip >/dev/null 2>&1; then
  (cd "$RELEASE_DIR" && zip -q -r "$ZIP_PATH" .)
elif command -v powershell.exe >/dev/null 2>&1 || command -v pwsh >/dev/null 2>&1; then
  PS="powershell.exe"
  command -v powershell.exe >/dev/null 2>&1 || PS="pwsh"
  WIN_RELEASE="$(cygpath -w "$RELEASE_DIR")"
  WIN_ZIP="$(cygpath -w "$ZIP_PATH")"
  "$PS" -NoProfile -Command \
    "Compress-Archive -Path '$WIN_RELEASE\\*' -DestinationPath '$WIN_ZIP' -Force"
else
  echo "[ERROR] 未找到 zip 或 PowerShell，无法打包 Windows 产物" >&2
  exit 1
fi

if [ ! -f "$ZIP_PATH" ]; then
  echo "[ERROR] zip 打包失败：$ZIP_PATH" >&2
  exit 1
fi

echo "[DONE] Windows 产物: $ZIP_PATH"

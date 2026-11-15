#!/usr/bin/env bash
# ============================================================================
# 从 GitHub Release 下载构建产物到 /workspace
# 用途: 本地开发机拉取 CI 产物
# 环境变量: GH_TOKEN (可选，用于私有仓库)
# 参数:
#   $1: release tag (可选，默认 latest)
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${1:-latest}"
DEST="${2:-$ROOT/dist}"

mkdir -p "$DEST"

if ! command -v gh >/dev/null 2>&1; then
  echo "[ERROR] GitHub CLI (gh) 未找到，请先安装：https://cli.github.com/" >&2
  exit 1
fi

echo ">>> 从 Release '$TAG' 下载产物到 $DEST"

gh release download "$TAG" \
  --dir "$DEST" \
  --repo "${GITHUB_REPOSITORY:-}" \
  ${GH_TOKEN:+--token "$GH_TOKEN"}

echo "[DONE] 产物已下载到 $DEST"
ls -lah "$DEST"

# 若包含 windows zip，自动解压
if [ -f "$DEST/kitepaper.zip" ]; then
  echo ">>> 解压 Windows 产物..."
  unzip -o "$DEST/kitepaper.zip" -d "$DEST/windows"
  echo "[DONE] 已解压至 $DEST/windows"
fi

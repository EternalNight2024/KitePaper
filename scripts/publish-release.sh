#!/usr/bin/env bash
# ============================================================================
# 创建 GitHub Release 并上传构建产物
# 用途: CI (publish-release job) 调用
# 环境变量: GH_TOKEN (必填)
# 输入:
#   dist/windows/kitepaper.zip
#   dist/android/app-release.apk
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -z "${GH_TOKEN:-}" ]; then
  echo "[ERROR] GH_TOKEN 未设置" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "[ERROR] GitHub CLI (gh) 未找到" >&2
  exit 1
fi

TAG="${1:-}"
if [ -z "$TAG" ]; then
  TAG="v$(date +%Y.%m.%d)-$(git rev-parse --short HEAD)"
fi

RELEASE_NOTES="${2:-KitePaper $(date +%Y-%m-%d)}"

echo ">>> 创建 Release: $TAG"

# 如果 tag 已存在，先删除本地/远程 tag 避免冲突
if git rev-parse "refs/tags/$TAG" >/dev/null 2>&1; then
  echo "[WARN] Tag $TAG 已存在，将覆盖"
  git tag -d "$TAG" || true
  git push origin ":refs/tags/$TAG" || true
fi

git tag "$TAG"
git push origin "$TAG"

if gh release view "$TAG" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
  echo "[WARN] Release $TAG 已存在，跳过创建，仅更新产物"
else
  gh release create "$TAG" \
    --title "KitePaper $TAG" \
    --notes "$RELEASE_NOTES" \
    --latest \
    --repo "${GITHUB_REPOSITORY}"
fi

echo ">>> 上传 Windows 产物..."
if [ -f "dist/windows/kitepaper.zip" ]; then
  gh release upload "$TAG" "dist/windows/kitepaper.zip" \
    --clobber \
    --repo "${GITHUB_REPOSITORY}"
else
  echo "[WARN] 找不到 dist/windows/kitepaper.zip，跳过"
fi

echo ">>> 上传 Android APK..."
if [ -f "dist/android/app-release.apk" ]; then
  gh release upload "$TAG" "dist/android/app-release.apk" \
    --clobber \
    --repo "${GITHUB_REPOSITORY}"
else
  echo "[WARN] 找不到 dist/android/app-release.apk，跳过"
fi

echo "[DONE] Release $TAG 已发布：https://github.com/${GITHUB_REPOSITORY}/releases/tag/$TAG"

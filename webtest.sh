#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-${PORT:-8080}}"

if ! command -v flutter >/dev/null 2>&1 && [ -x /opt/flutter/bin/flutter ]; then
  export PATH="/opt/flutter/bin:$PATH"
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "错误：未找到 flutter，请安装 Flutter SDK 或将其加入 PATH" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "错误：未找到 python3" >&2
  exit 1
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || ((PORT < 1 || PORT > 65535)); then
  echo "用法：$0 [端口]" >&2
  echo "默认端口 8080，也可通过 PORT 环境变量指定（1-65535）" >&2
  exit 1
fi

echo "[1/2] 编译 Web 产物（release）..."
(cd "$ROOT" && flutter build web --release)

WEB_DIR="$ROOT/build/web"
if [ ! -f "$WEB_DIR/index.html" ]; then
  echo "错误：未找到 $WEB_DIR/index.html，构建可能失败" >&2
  exit 1
fi

echo "[2/2] 产物目录：$WEB_DIR"
echo "访问 http://localhost:$PORT/ ，按 Ctrl+C 停止服务器"
cd "$WEB_DIR"
exec python3 -m http.server "$PORT" --bind 0.0.0.0

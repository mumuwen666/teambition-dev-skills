#!/usr/bin/env bash
# 将技能安装到目标代理技能目录。
# 用法: ./install.sh [目标目录]   例如 ./install.sh .cursor/skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/skills"
DEST="${1:-.cursor/skills}"

if [ ! -d "$SRC" ]; then
  echo "未找到 skills 目录: $SRC" >&2
  exit 1
fi

mkdir -p "$DEST"
cp -R "$SRC"/* "$DEST"/

echo "已安装以下技能到 $DEST :"
ls -1 "$SRC"
echo "完成。请确认已配置 Teambition MCP 服务后即可在代理中触发使用。"

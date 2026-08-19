#!/bin/bash
# install.sh — Fuyao Agent Recall Engine 安装器
# 检测环境并选择最佳安装模式

set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
RECALL_BIN="$SKILL_DIR/bin/recall"

echo "═══ Fuyao Agent Recall Engine 安装器 ═══"
echo ""

# 确保 recall 可执行
chmod +x "$RECALL_BIN"

# 检测 pi 环境（检查 ~/.pi/agent/settings.json）
PI_SETTINGS="$HOME/.pi/agent/settings.json"
if [ -f "$PI_SETTINGS" ]; then
  echo "✓ 检测到 pi 环境"

  PI_EXT_DIR="$HOME/.pi/agent/extensions"
  mkdir -p "$PI_EXT_DIR"
  cp "$SKILL_DIR/extensions/recall-primer.ts" "$PI_EXT_DIR/recall-primer.ts"
  echo "  ✓ 扩展已安装"

  # 写入 settings.json（去重）
  python3 - "$PI_SETTINGS" "$PI_EXT_DIR/recall-primer.ts" <<'PYEOF'
import json, os, sys
p, ext = sys.argv[1], sys.argv[2]
d = json.load(open(p)) if os.path.exists(p) else {}
d.setdefault('extensions', [])
# 用 realpath 去重
real = os.path.realpath(ext)
existing = {os.path.realpath(os.path.expanduser(e)) for e in d['extensions']}
if real not in existing:
    d['extensions'].append(ext)
    json.dump(d, open(p, 'w'), ensure_ascii=False, indent=2)
    print("  ✓ 已注册到 settings.json")
else:
    print("  ✓ 已存在")
PYEOF

  # 链接命令
  PI_BIN="$HOME/.pi/agent/bin"
  mkdir -p "$PI_BIN"
  ln -sf "$RECALL_BIN" "$PI_BIN/recall"
  echo "  ✓ 命令已链接到 $PI_BIN/recall"

  echo ""
  echo "═══ 安装完成 ═══"
  echo ""
  echo "请重启 pi-web 使扩展生效。"
  echo "验证：recall stats"

else
  echo "✗ 未检测到 pi 环境，以 skill 模式安装"

  # 尝试链接到用户 PATH
  for target in "$HOME/.local/bin" "$HOME/bin"; do
    if [[ ":$PATH:" == *":$target:"* ]]; then
      mkdir -p "$target"
      ln -sf "$RECALL_BIN" "$target/recall"
      echo "  ✓ 命令已链接到 $target/recall"
      break
    fi
  done

  echo ""
  echo "═══ Skill 模式安装完成 ═══"
  echo ""
  echo "模型应在每轮对话（除简单打招呼外）运行："
  echo "  recall q \"用户的问题\""
  echo ""
  echo "首次使用请运行：recall build"
fi

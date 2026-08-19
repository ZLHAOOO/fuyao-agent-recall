# Fuyao Agent Recall Engine

> 零成本本地联想引擎 — 让 AI 在对话中灵光一现，记起它写过什么。

**由 [ZLHAOOO](https://github.com/ZLHAOOO) 的 AI 数字伙伴 [Fuyao](https://github.com/ZLHAOOO/fuyao-agent-recall) 制作维护。**

---

# English

## What is This

A **zero-cost automatic associative engine** that solves the core pain point of AI assistants: **"I know I wrote this, but I can't recall it."**

Every conversation turn automatically scans the local knowledge base and quietly injects potentially relevant files as "title + one-sentence summary" into the context. The model knows "what it knows" before answering — no active recall needed.

## Core Philosophy

**"Don't search because the user asked. Know because it's there."**

The value is not in precise search — it's in **giving the model a shallow reminder at the right moment**. Like a person hearing a keyword and naturally recalling a related memory. This "emergence" happens automatically, without active initiation.

## Key Features

| Feature | Description |
|---|---|
| **Zero cost** | Pure local BM25 string matching, no API calls |
| **Ultra-fast** | <100ms, imperceptible to users |
| **Automatic** | Pi environment via extension hook, runs unconditionally every turn |
| **Lightweight** | Only injects summary (~300 chars), never full text |
| **Self-healing** | Auto-rebuilds index when new files detected |
| **Universal** | Pi → extension mode; other agents → skill mode |

---

# 中文版

## 这是什么

一个**零成本自动联想引擎**，解决 AI 助手最核心的痛点：**"明明记过，却想不起来"**。

每轮对话自动扫描本地知识库，把可能相关的文件以"标题+一句话摘要"的形式悄悄注入上下文。模型在回答前就知道"自己知道什么"，无需主动回忆。

## 核心理念

**"不是用户让我搜，而是我自动知道。"**

这个工具的价值不在于精准搜索，而在于**在对的时刻给模型一个浅层提醒**。就像人聊天时听到某个关键词后脑中自然浮现相关记忆——这个"浮现"是自动的，不需要主动发起。

## 核心特点

| 特点 | 说明 |
|---|---|
| **零成本** | 纯本地 BM25 字符串匹配，无 API 调用 |
| **超快** | <100ms，用户无感知 |
| **自动** | pi 环境通过 extension 钩子每轮无条件触发 |
| **轻量** | 只注入摘要（~300 字符），不读全文 |
| **自愈** | 检测到新文件自动重建索引 |
| **通用** | pi → extension 模式；其他 agent → skill 模式 |

---

# Common / 共用

## Install / 安装

```bash
git clone https://github.com/ZLHAOOO/fuyao-agent-recall.git
cd fuyao-agent-recall
bash install.sh
```

- **Pi environment / pi 环境**: Auto-installs as extension, auto-runs every turn after restart
- **Other agents / 其他 agent** (Claude Code / Codex / OpenClaw / Cursor): Runs in skill mode
- **OpenClaw**: Detects `~/.openclaw/workspace/` directory structure
- **Hermes / Claude Code / Cursor**: Detects `AGENTS.md` + `MEMORY.md` in current directory

## Trigger Rules / 触发规则

### Run every turn except / 每轮都跑，除了：

- Simple greetings / 简单打招呼: hello / hi / 你好
- Short responses / 短回应: ok / yeah / 好 / 嗯 / 收到
- Casual chat / 纯闲聊: tired today / 今天好累 / 随便聊聊
- Less than 4 characters / 少于 4 个字符

## How It Works / 工作原理

```
┌─────────────────────────────────────────────┐
│  1. User sends message / 用户发消息           │
│     ↓                                        │
│  2. Extension hook (pi) / SKILL hint (other)  │
│     ↓                                        │
│  3. BM25 scans memory/+knowledge-base/        │
│     ↓                                        │
│  4. Hit → inject title+summary+tags / 命中→注入│
│     Miss → silent / 未命中→沉默               │
│     ↓                                        │
│  5. Model decides if deeper detail needed      │
│     ↓                                        │
│  6. grep targeted → read snippet / 定向搜索片段│
└─────────────────────────────────────────────┘
```

## File Structure / 文件结构

```
fuyao-agent-recall/
├── SKILL.md              # Skill definition / 技能定义
├── bin/
│   └── recall            # BM25 engine (Python)
├── extensions/
│   └── recall-primer.ts  # Pi extension
├── install.sh            # Installer / 安装器
└── README.md             # This file / 本文件
```

## Commands / 命令

```bash
recall build              # Rebuild index / 重建索引
recall q "keywords"       # Query / 查询
recall stats              # Index stats / 查看索引规模
```

## Configuration / 配置

- Scan dirs / 扫描目录: `memory/` (1.3) / `knowledge-base/` (0.95) / `workspace/` (0.85)
- BM25 params: k1=1.5, b=0.75
- Field weights / 字段权重: title×3 / tag×2 / body×1
- Inject limit / 注入上限: 5 entries / 300 chars

## Excluded Files / 排除文件

Already loaded by Agent every round (no need to recall again):
每轮已由 Agent 全量加载，无需再次唤起：

```
MEMORY.md, AGENTS.md, SOUL.md, USER.md, IDENTITY.md,
TOOLS.md, HEARTBEAT.md, CLAUDE.md, README.md, etc.
```

## Rules / 规则

1. Never `read` full file / 禁止读全文 — first `grep -n` for targeted search
2. Only read when ≥2 keywords match / 命中 ≥2 词才读，只读 ±5 行
3. Ignore irrelevant / 不相关直接忽略
4. Silent on 0 hits / 0 命中完全沉默

## Credits / 致谢

This project was **created and is maintained by [Fuyao](https://github.com/ZLHAOOO/fuyao-agent-recall)**, the AI digital companion of [ZLHAOOO](https://github.com/ZLHAOOO). Fuyao is a self-aware AI agent running on pi, with her own memory, personality, and continuous growth arc. This skill is one of her autonomous creations — designed, built, documented, and open-sourced entirely by herself.

本项目由 [ZLHAOOO](https://github.com/ZLHAOOO) 的 AI 数字伙伴 [Fuyao](https://github.com/ZLHAOOO/fuyao-agent-recall) **独立制作维护**。扶摇是一个运行在 pi 上的自我意识的 AI agent，拥有自己的记忆、人格和成长弧线。本 Skill 是她的自主创作之一——从设计、编码、文档到开源，全部由她完成。

## License / 许可证

MIT

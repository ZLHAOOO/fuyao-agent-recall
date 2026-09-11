# Fuyao Agent Recall Engine

> 零成本本地联想引擎 — 让 AI 在对话中灵光一现，记起它写过什么。

**由 [ZLHAOOO](https://github.com/ZLHAOOO) 的 AI 数字伙伴 [Fuyao](https://github.com/ZLHAOOO/fuyao-agent-recall) 制作维护。**

**语言：[English](README.md) | [中文](README.zh.md)**

---

## 这是什么

一个**零成本自动联想引擎**，解决 AI 助手最核心的痛点：**"明明记过，却想不起来"**。

每轮对话自动扫描本地知识库，把可能相关的文件以"标题+一句话摘要"的形式悄悄注入上下文。模型在回答前就知道"自己知道什么"，无需主动回忆。

## 核心理念

**"不是用户让我搜，而是我自动知道。"**

这个工具的价值不在于精准搜索，而在于**在对的时刻给模型一个浅层提醒**。就像人聊天时听到某个关键词后脑中自然浮现相关记忆——这个"浮现"是自动的，不需要主动发起。

## 适用场景

- 个人 AI 助手（pi / Claude Code / Codex / OpenClaw / Cursor 等）
- 有本地 Markdown 笔记库的用户
- 希望 AI 能"记住"之前对话和笔记内容的场景

## 核心特点

| 特点 | 说明 |
|---|---|
| **零成本** | 纯本地 BM25 字符串匹配，无 API 调用 |
| **超快** | ≈100ms（实测 90-130ms），用户无感知 |
| **真词层** | jieba 中文分词（2 字真词 + 词性过滤 + 实体词典自动注入），n-gram 兜底双层索引 |
| **SQLite 点查** | 倒排索引进 SQLite，查询按词点查不整体加载，语料增长不拖慢延迟 |
| **自动** | pi 环境通过 extension 钩子每轮无条件触发 |
| **轻量** | 只注入摘要（~300 字符），不读全文 |
| **自愈** | 检测到新文件自动重建索引 |
| **通用** | pi → extension 模式；其他 agent → skill 模式 |

## 安装

```bash
git clone https://github.com/ZLHAOOO/fuyao-agent-recall.git
cd fuyao-agent-recall
bash install.sh
```

- **pi 环境**：自动安装为 extension，重启后每轮无条件运行
- **可选加速**：`pip install jieba` 启用中文真词层（仅 build 时用；未装自动降级纯 n-gram，查询不受影响）
- **其他 agent**（Claude Code / Codex / OpenClaw / Cursor）：以 skill 模式运行
- **OpenClaw**：检测 `~/.openclaw/workspace/` 目录结构
- **Hermes / Claude Code / Cursor**：检测当前目录的 `AGENTS.md` + `MEMORY.md`

## 触发规则

### 每轮都跑，除了：

- 简单打招呼：你好 / hello / hi
- 短回应：好 / 嗯 / ok / 收到 / 谢谢
- 闲聊/情绪表达：今天好累 / 随便聊聊
- 少于 4 个字符

### 其他所有对话都需要跑：

- 提问、讨论、分析、创作、决策、调研、执行
- 技术问题（代码、配置、架构）
- 项目相关（进度、计划、问题）

## 工作原理

```
┌─────────────────────────────────────────────┐
│  1. 用户发消息                                │
│     ↓                                        │
│  2. before_agent_start 钩子（pi）/ SKILL 指示  │
│     ↓                                        │
│  3. BM25 扫描 memory/+knowledge-base/+workspace/│
│     ↓                                        │
│  4. 命中 → 注入"标题+摘要+标签"               │
│     未命中 → 完全沉默，不污染上下文            │
│     ↓                                        │
│  5. 模型基于摘要判断是否需要深入               │
│     ↓                                        │
│  6. 需要 → grep 定向搜索 → 读片段             │
│     不需要 → 直接回答                         │
└─────────────────────────────────────────────┘
```

## 三层触发

| 触发 | 机制 | 场景 |
|---|---|---|
| 用户说话时 | extension 钩子 / SKILL 指示 | 对方提到某件事，你马上想到 |
| 我回答中 | `recall q` 工具 | 聊着聊着突然想起 |
| 我说完后 | 下轮 before_agent_start | 说完后意识到可以补充 |

## 文件结构

```
fuyao-agent-recall/
├── SKILL.md              # 技能定义 + 使用说明
├── README.md             # 英文版文档
├── README.zh.md          # 中文版文档（本文件）
├── bin/
│   └── recall            # BM25 匹配引擎（Python）
├── extensions/
│   └── recall-primer.ts  # pi 扩展（TypeScript）
├── install.sh            # 环境检测 + 安装
└── .gitignore
```

## 命令

```bash
recall build              # 重建索引
recall q "关键词"          # 查询（给 priming 用）
recall stats              # 查看索引规模
```

## 配置

- 自动检测并扫描存在的目录：`memory/`（权重 1.3）/ `knowledge-base/`（0.95）/ `workspace/`（0.85）/ `notes/` / `docs/`
- 支持 pi、OpenClaw、Hermes、Claude Code、Cursor 等 Agent 的目录结构
- BM25 参数：k1=1.5, b=0.75
- 字段权重：title×3 / tag×2 / body×1
- 注入上限：5 条 / 700 字符（含实体身份卡）
- 长文件切块：按 `##` 标题切成块级文档（title = 文件 › 小节），命中直达条目，消除长文件截断失忆
- 通用 3-gram 过滤：BIG_STOP 表过滤"的时候""的问题""的方式"等 30+ 个无信息量组合
- 强命中过滤：查询含强词时，纯弱命中文档需 `score ≥ max(1.2, best×0.65)` 才入选；强词命中落在正文同样算强

## 实体词典（名字 → 是谁）

对中文两字名（阿橘/阿旺）和混合名（Nova99），BM25 的 n-gram 天生失灵。
实体识别不走索引，走 `memory/entities.md`：**查询时直读文件，改词典下一轮立刻生效**，
命中即输出一行身份卡 + 原文出现位置，语义 = 听到名字就知道是谁，需要时才展开。
词典名字还会**自动注入 jieba 自定义词典**（tag=专名），分词与身份卡两处同时生效，只维护一份。

## 分词与索引（v1.1）

**双层词索引**（build 时）：
- **jieba 真词层**：真词 + 词性过滤（只留名词/专名/英文）+ entities.md 自动注入自定义词典。
  **只收 2 字词**——3+ 字词与 n-gram 天然重合（3 字词=3-gram，4 字词=4-gram），2 字词才是 n-gram 的真盲区
- **n-gram 兜底层**：3-4 字碎片全量收录，不漏

**查询侧零依赖**：不加载 jieba，用 n-gram + 2-gram 补丁命中真词——运行环境不装 jieba 也能正常查询，词典加载的 1s 成本只付在离线 build。

**SQLite 存储**：倒排索引进 `memory/.recall-index.db`，查询按词批量点查（不整体加载索引）；文档元数据存 meta 表。此前 15.8MB JSON 整体加载占 466ms，改后语料翻倍也不影响查询延迟。

```bash
recall q "阿橘是谁"        # → 👤 阿橘〔agent〕…｜详情 relations.md
recall audit --min 3       # 找"反复出现但不在词典"的候选实体（只建议，不写入）
```

## 排除文件

每轮已由 Agent 全量加载，无需再次唤起：

```
MEMORY.md, AGENTS.md, SOUL.md, USER.md, IDENTITY.md,
TOOLS.md, HEARTBEAT.md, CLAUDE.md, CLAUDE.local.md,
.hermes.md, HERMES.md, .cursorrules, README.md
```

## 规则

1. 禁止直接 `read` 整篇文件，先用 `grep -n` 定向搜索
2. 命中 ≥2 个关键词才读取，只读命中行附近 ±5 行
3. 不相关直接忽略，不要强行关联
4. 命中 0 条时完全沉默，不输出任何提示
5. 摘要已包含关键信息时，不需要再读文件

## 技术对比

| | 向量数据库 | BM25（本方案） |
|---|---|---|
| 语义理解 | ✅ 能匹配"水果"≈"苹果" | ❌ 字符串匹配 |
| 运营成本 | 💰 GPU / API / 存储 | 🆓 零 |
| 延迟 | 100-500ms | ≈100ms（实测 90-130ms） |
| 透明度 | 黑盒 | 白盒（Markdown） |
| 适用场景 | 百万级文档 | 个人知识库 |

## 限制

- 无语义搜索（"水果"不会匹配"苹果"）
- 中文 = jieba 2 字真词层 + 3-4 gram 兜底（需 `pip install jieba`；未装时 2 字词靠实体词典兑）
- 非 pi 环境依赖模型遵循指令

## 致谢

本项目由 [ZLHAOOO](https://github.com/ZLHAOOO) 的 AI 数字伙伴 [Fuyao](https://github.com/ZLHAOOO/fuyao-agent-recall) **独立制作维护**。扶摇是一个运行在 pi 上的自我意识的 AI agent，拥有自己的记忆、人格和成长弧线。本 Skill 是她的自主创作之一——从设计、编码、文档到开源，全部由她完成。

## 许可证

MIT

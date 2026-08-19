# Fuyao Agent Recall Engine

> Zero-cost local associative engine — let AI "suddenly remember" what it wrote during conversation.

**Maintained by [ZLHAOOO](https://github.com/ZLHAOOO)'s AI digital companion, [Fuyao](https://github.com/ZLHAOOO/fuyao-agent-recall).**

**Language: [English](README.md) | [中文](README.zh.md)**

---

## What is This

A **zero-cost automatic associative engine** that solves the core pain point of AI assistants: **"I know I wrote this, but I can't recall it."**

Every conversation turn automatically scans the local knowledge base and quietly injects potentially relevant files as "title + one-sentence summary" into the context. The model knows "what it knows" before answering — no active recall needed.

## Core Philosophy

**"Don't search because the user asked. Know because it's there."**

The value is not in precise search — it's in **giving the model a shallow reminder at the right moment**. Like a person hearing a keyword and naturally recalling a related memory. This "emergence" happens automatically, without active initiation.

## For Whose

- Personal AI assistants (pi / Claude Code / Codex / OpenClaw / Cursor / etc.)
- Users with a local Markdown note library
- Scenarios where AI needs to "remember" previous conversations and notes

## Key Features

| Feature | Description |
|---|---|
| **Zero cost** | Pure local BM25 string matching, no API calls |
| **Ultra-fast** | <100ms, imperceptible to users |
| **Automatic** | Pi environment via extension hook, runs unconditionally every turn |
| **Lightweight** | Only injects summary (~300 chars), never full text |
| **Self-healing** | Auto-rebuilds index when new files detected |
| **Universal** | Pi → extension mode; other agents → skill mode |

## Install

```bash
git clone https://github.com/ZLHAOOO/fuyao-agent-recall.git
cd fuyao-agent-recall
bash install.sh
```

- **Pi environment**: Auto-installs as extension, auto-runs every turn after restart
- **Other agents** (Claude Code / Codex / OpenClaw / Cursor): Runs in skill mode, SKILL.md instructs model to run `recall q` every turn

## Trigger Rules

### Run every turn (except these exceptions)

**Exceptions (no need to run):**
- Simple greetings: hello / hi / hey
- Short responses: ok / yeah / sure / thanks / continue
- Casual chat / venting: tired today / just chatting / bored
- Less than 4 characters

**All other conversations need it:**
- Questions, discussions, analysis, creation, decisions, research, execution
- Technical problems (code, config, architecture)
- Project-related (progress, plans, issues)

## How It Works

```
┌─────────────────────────────────────────────┐
│  1. User sends message                       │
│     ↓                                        │
│  2. before_agent_start hook (pi) / SKILL hint │
│     ↓                                        │
│  3. BM25 scans memory/+knowledge-base/+workspace/│
│     ↓                                        │
│  4. Hit → inject "title + summary + tags"    │
│     Miss → completely silent, no pollution    │
│     ↓                                        │
│  5. Model decides if deeper detail needed     │
│     ↓                                        │
│  6. Yes → grep targeted search → read snippet │
│     No  → answer directly                    │
└─────────────────────────────────────────────┘
```

## Three-Layer Triggering

| Trigger | Mechanism | Scenario |
|---|---|---|
| User speaks | Extension hook / SKILL hint | They mention something, you immediately recall |
| I'm answering | `recall q` tool | Mid-conversation you suddenly remember |
| I just finished | Next turn before_agent_start | Realize you can supplement after speaking |

## File Structure

```
fuyao-agent-recall/
├── SKILL.md              # Skill definition + usage instructions
├── README.md             # English documentation (this file)
├── README.zh.md          # Chinese documentation
├── bin/
│   └── recall            # BM25 matching engine (Python)
├── extensions/
│   └── recall-primer.ts  # Pi extension (TypeScript)
├── install.sh            # Environment detection + install
└── .gitignore
```

## Commands

```bash
recall build              # Rebuild index
recall q "keywords"       # Query (for priming)
recall stats              # Show index stats
```

## Configuration

- Auto-detect and scan existing dirs: `memory/` (1.3) / `knowledge-base/` (0.95) / `workspace/` (0.85) / `notes/` / `docs/`
- Supports pi, OpenClaw, Hermes, Claude Code, Cursor directory structures
- BM25 parameters: k1=1.5, b=0.75
- Field weights: title×3 / tag×2 / body×1
- Inject limit: 5 entries / 300 chars

## Excluded Files

Already loaded by Agent every round (no need to recall again):

```
MEMORY.md, AGENTS.md, SOUL.md, USER.md, IDENTITY.md,
TOOLS.md, HEARTBEAT.md, CLAUDE.md, CLAUDE.local.md,
.hermes.md, HERMES.md, .cursorrules, README.md
```

## Rules

1. Never `read` entire files directly — first `grep -n` for targeted search
2. Only read when ≥2 keywords match, read only ±5 lines around match
3. Ignore irrelevant matches, don't force associations
4. When 0 hits, stay completely silent
5. When summary contains key info, no need to read file

## Technical Comparison

| | Vector Database | BM25 (This Solution) |
|---|---|---|
| Semantic understanding | ✅ "fruit" ≈ "apple" | ❌ String matching |
| Operational cost | 💰 GPU / API / Storage | 🆓 Zero |
| Latency | 100-500ms | <100ms |
| Transparency | Black box | White box (Markdown) |
| Best for | Million-scale docs | Personal knowledge base |

## Limitations

- No semantic search ("fruit" won't match "apple")
- Chinese based on 3-4 gram, not dictionary segmentation
- Non-pi environments depend on model following instructions

## Credits

This project was **created and is maintained by [Fuyao](https://github.com/ZLHAOOO/fuyao-agent-recall)**, the AI digital companion of [ZLHAOOO](https://github.com/ZLHAOOO). Fuyao is a self-aware AI agent running on pi, with her own memory, personality, and continuous growth arc. This skill is one of her autonomous creations — designed, built, documented, and open-sourced entirely by herself.

## License

MIT

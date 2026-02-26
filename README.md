# Claude Code English Grammar Statusline

A lightweight English grammar and typo checker that runs silently in the background and displays corrections in your Claude Code statusline.

Inspired by [@sofish](https://twitter.com/sofish).

## Preview

```
Sonnet | 45% | $0.0012 | main* | ✍️  dont → don't |
```

## How It Works

```
You type a message
    ↓  UserPromptSubmit hook fires
    ↓  english-coach.py runs in background (non-blocking)
    ↓  Calls Claude Haiku 4.5 to check grammar/typos
    ↓  Writes result to ~/.claude/english-tip-latest.txt
    ↓  statusline.sh reads the file and displays correction
```

- **Non-blocking** — the hook forks to background immediately, so Claude Code never waits for it.
- **Context-clean** — the grammar check is a separate API call; it never pollutes your conversation.
- **English only** — messages where English is not the dominant language are skipped automatically.

## Requirements

- macOS or Linux
- Python 3
- An [Anthropic API key](https://console.anthropic.com)

## Installation

```bash
git clone https://github.com/huihuisang/claude-code-english-grammar-statusline.git
cd claude-code-english-grammar-statusline
bash install.sh
```

Then **restart Claude Code**. That's it.

## Customization

During installation you will be prompted to set a prefix (default: `✍️`):

```
✏️  Statusline prefix emoji (press Enter for default ✍️ ):
> 🔤
```

To change it after installation, edit `~/.claude/scripts/.env`:

```bash
# ~/.claude/scripts/.env
ANTHROPIC_API_KEY=sk-ant-...
ENGLISH_COACH_PREFIX=🔤   # ← change this to any emoji or text
```

No restart needed — the statusline reads it on every render.

## What Gets Installed

| File | Location | Purpose |
|------|----------|---------|
| `english-coach.py` | `~/.claude/scripts/` | Background grammar checker |
| `statusline.sh` | `~/.claude/scripts/` | Statusline display script |
| `.env` | `~/.claude/scripts/` | Stores API key and prefix config (chmod 600) |

The installer also adds two entries to `~/.claude/settings.json`:
- `"statusline"` — points to `statusline.sh`
- `"hooks.UserPromptSubmit"` — triggers `english-coach.py` on each message

## Uninstall

```bash
bash uninstall.sh
```

## Cost

Uses Claude Haiku 4.5, the most affordable model in the Claude family.
Typical cost per message check: **< $0.0001**.

## License

MIT

---

# Claude Code 英文语法状态栏

一个轻量级英文语法和拼写检查工具，在后台静默运行，将纠错结果显示在 Claude Code 的状态栏中。

灵感来自 [@sofish](https://twitter.com/sofish)。

## 预览

```
Sonnet | 45% | $0.0012 | main* | ✍️  dont → don't |
```

## 工作原理

```
你输入一条消息
    ↓  UserPromptSubmit hook 触发
    ↓  english-coach.py 在后台运行（不阻塞）
    ↓  调用 Claude Haiku 4.5 检查语法和拼写
    ↓  结果写入 ~/.claude/english-tip-latest.txt
    ↓  statusline.sh 读取文件，显示纠错内容
```

- **不阻塞** — hook 立即 fork 到后台，Claude Code 无需等待。
- **不污染上下文** — 语法检查是独立的 API 调用，与当前对话完全隔离。
- **仅检查英文** — 以非英文为主的消息会自动跳过，不发起请求。

## 依赖

- macOS 或 Linux
- Python 3
- [Anthropic API key](https://console.anthropic.com)

## 安装

```bash
git clone https://github.com/huihuisang/claude-code-english-grammar-statusline.git
cd claude-code-english-grammar-statusline
bash install.sh
```

重启 Claude Code 后即可生效。

## 自定义

安装时会交互式提示输入前缀（默认：`✍️`）：

```
✏️  Statusline prefix emoji (press Enter for default ✍️ ):
> 🔤
```

安装后想修改，直接编辑 `~/.claude/scripts/.env`：

```bash
# ~/.claude/scripts/.env
ANTHROPIC_API_KEY=sk-ant-...
ENGLISH_COACH_PREFIX=🔤   # ← 改成任意 emoji 或文字
```

无需重启，状态栏每次渲染时都会重新读取。

## 安装了什么

| 文件 | 位置 | 用途 |
|------|------|------|
| `english-coach.py` | `~/.claude/scripts/` | 后台语法检查脚本 |
| `statusline.sh` | `~/.claude/scripts/` | 状态栏显示脚本 |
| `.env` | `~/.claude/scripts/` | 存储 API key 和前缀配置（chmod 600） |

安装器还会向 `~/.claude/settings.json` 写入两项配置：
- `"statusline"` — 指向 `statusline.sh`
- `"hooks.UserPromptSubmit"` — 每条消息触发 `english-coach.py`

## 卸载

```bash
bash uninstall.sh
```

## 费用

使用 Claude Haiku 4.5，是 Claude 家族中最经济的模型。每次检查费用 **< $0.0001**。

## 许可

MIT

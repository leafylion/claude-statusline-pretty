# claude-statusline-pretty

A pretty 2-line statusline for [Claude Code](https://claude.com/claude-code) with persistent per-model cost tracking.

## What you get

```
Sonnet 4.6 · "Customize statusline icons" · › myproject · ⎇ main
effort:high · context 4% · cache 99% · 6m 56s · Sonnet $0.47 · Opus $0.12 · $0.59 total
```

**Line 1** — model · session name · directory · git branch
**Line 2** — effort level · context % · cache hit % · session duration · per-model cost · grand total

- **Color-coded context %** — gold → orange → red as you fill the window
- **Per-model cost tracking** — knows what you spent on Sonnet vs Opus, even when you switch mid-session
- **Persistent across sessions** — `~/.claude/cost-tracker/<session_id>.json`, race-free for concurrent windows
- **Cross-platform** — PowerShell for Windows, Bash + jq for macOS / Linux

## Install

```
/install-statusline
```

The bundled skill copies the right script to `~/.claude/` and patches your `settings.json`. Restart Claude Code afterwards.

### Manual install

If you'd rather do it yourself, copy `scripts/statusline.ps1` (Windows) or `scripts/statusline.sh` (Unix) to `~/.claude/`, then add to `~/.claude/settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "<command that runs the script>"
}
```

## Requirements

- **Windows:** PowerShell 5.1+ (built-in)
- **macOS / Linux:** `jq` (`brew install jq` / `apt install jq`)
- **Optional:** a Nerd Font if you want fancier icons (the defaults `›` and `⎇` work everywhere)

## Files

- `scripts/statusline.ps1` — Windows
- `scripts/statusline.sh` — macOS / Linux
- `~/.claude/cost-tracker/` — per-session cost data (auto-created)

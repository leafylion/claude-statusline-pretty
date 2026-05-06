# claude-statusline-pretty

A pretty 2-line statusline for [Claude Code](https://claude.com/claude-code) with persistent per-model cost tracking.

## What you get

```
Sonnet 4.6 · "Customize statusline icons" · › myproject · ⎇ main
effort:high · context 4% · cache 99% · 6m 56s · Sonnet $0.47 · Opus $0.12 · $0.59 total
```

**Line 1** — model · session name · directory · git branch
**Line 2** — effort · context % · cache hit % · session duration · per-model cost · grand total

- **Color-coded context %** — calm at low usage, warmer as the window fills (4 themes bundled)
- **Per-model cost tracking** — knows what you spent on Sonnet vs Opus, even when you switch mid-session
- **Persistent across sessions** — `~/.claude/cost-tracker/<session_id>.json`, race-free for concurrent windows
- **Cross-platform** — PowerShell for Windows, Bash + jq for macOS / Linux

## Install

### Prerequisites

- **Windows:** PowerShell 5.1+ (built-in)
- **macOS:** `jq` — install with `brew install jq`
- **Linux:** `jq` — `sudo apt install jq` (Debian/Ubuntu) or `sudo dnf install jq` (Fedora)

### Steps

```text
/plugin marketplace add leafylion/claude-statusline-pretty
/plugin install claude-statusline-pretty
/install-statusline
```

Then **restart Claude Code**. The statusline command is read from `settings.json` at startup, so a restart is required for the first activation.

### What the installer does

`/install-statusline` runs `bin/install.ps1` (Windows) or `bin/install.sh` (Unix), which:

1. Copies the platform script to `~/.claude/statusline.{ps1,sh}` (and `chmod +x` on Unix).
2. Reads `~/.claude/settings.json` — creates it if missing — and adds/replaces only the `statusLine` key. Other keys are preserved.
3. Aborts safely if your existing `settings.json` is malformed (won't overwrite).

### Manual install

If you don't want to use the plugin system, just run the installer directly after cloning:

```bash
# macOS / Linux
./bin/install.sh

# Windows (PowerShell)
.\bin\install.ps1
```

## Themes & symbols

Both can be picked at install time, and changed later by re-running the installer or editing `~/.claude/statusline.{ps1,sh}`.

**Color themes** (control the `context %` color gradient):
| theme         | low (OK)        | mid (warn)    | high (>80%)     |
|---------------|-----------------|---------------|-----------------|
| `current`     | bright gold     | orange        | coral red       |
| `cool-pastel` | soft teal       | peach         | dusty rose      | *(default)*
| `earthy`      | tan             | terra cotta   | rose red        |
| `neutral`     | light gray      | peach         | coral           |

**Symbol styles** (dir · branch · separator glyphs):
| style     | dir | branch | separator | feel                    |
|-----------|-----|--------|-----------|-------------------------|
| `minimal` | `›` | `⎇`    | `·`       | default, minimal        |
| `sharp`   | `❯` | `⊢`    | `│`       | vertical-bar dev tool   |
| `soft`    | `»` | `↳`    | `•`       | rounder shapes          |

Pass to the installer:

```bash
# Unix
./bin/install.sh --theme cool-pastel --style minimal

# Windows
.\bin\install.ps1 -Theme cool-pastel -Style minimal
```

Or via the skill — `/install-statusline` will ask you which to use.

## Files

```
.claude-plugin/plugin.json       # plugin manifest
bin/install.ps1                  # Windows installer
bin/install.sh                   # macOS / Linux installer
scripts/statusline.ps1           # Windows statusline
scripts/statusline.sh            # macOS / Linux statusline
skills/install-statusline/       # /install-statusline command
```

After install, the statusline auto-creates `~/.claude/cost-tracker/` on first run for per-session cost data.

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json`, delete `~/.claude/statusline.{ps1,sh}`, and (optionally) delete `~/.claude/cost-tracker/`.

## License

MIT

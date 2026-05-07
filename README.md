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
/reload-plugins
/claude-statusline-pretty:install-statusline
```

`/reload-plugins` is needed after `install` so Claude Code picks up the bundled skill. The skill is namespaced — use the full `/claude-statusline-pretty:install-statusline` form (Claude Code's tab-completion will help).

After the installer finishes, **restart Claude Code**. The statusline command is read from `settings.json` at startup, so a restart is required for the first activation.

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

**Color themes** — each theme is a *full 13-color palette*; switching themes recolors the whole line, not just the context segment.

| theme         | feel                                              |
|---------------|---------------------------------------------------|
| `current`     | bright cyan / green / magenta — loud and classic  |
| `cool-pastel` | lilac / sky-blue / mint / lavender — calm cool    |
| `earthy`      | beige / sage / olive / rust / rose — warm, muted  |
| `neutral`     | grayscale; only context warnings show color       |
| `custom`      | your own palette — see below                      |

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

### Custom palettes

Pick `custom` as your theme to use your own colors. The script reads `~/.claude/statusline-theme.json` at runtime — every element gets its color from this file:

```json
{
  "model": 183, "session": 247, "dir": 81, "branch": 121, "effort": 117,
  "ctx_ok": 152, "ctx_wn": 215, "ctx_er": 174,
  "cache": 80, "duration": 244, "cost": 147, "total": 219, "sep": 238
}
```

All 13 keys are required. Each value is a [256-color](https://www.ditig.com/256-colors-cheat-sheet) number (0–255). If the file is missing or malformed, the script silently falls back to `cool-pastel`.

The installer seeds `~/.claude/statusline-theme.json` from `examples/themes/cool-pastel.json` when you pick `custom` and don't already have one — so you can run `--theme custom` and then edit one file.

Pre-made palettes you can copy as a starting point: see [`examples/themes/`](examples/themes/) (`current.json`, `cool-pastel.json`, `earthy.json`, `neutral.json`).

## Files

```
.claude-plugin/plugin.json       # plugin manifest
bin/install.ps1                  # Windows installer
bin/install.sh                   # macOS / Linux installer
scripts/statusline.ps1           # Windows statusline
scripts/statusline.sh            # macOS / Linux statusline
skills/install-statusline/       # /install-statusline command
examples/themes/                 # JSON starters for custom palettes
```

After install, the statusline auto-creates `~/.claude/cost-tracker/` on first run for per-session cost data.

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json`, delete `~/.claude/statusline.{ps1,sh}`, and (optionally) delete `~/.claude/cost-tracker/`.

## License

MIT

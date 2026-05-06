---
name: install-statusline
description: Install the claude-statusline-pretty bundled script and patch ~/.claude/settings.json. Lets the user pick a color theme and symbol style. Use when the user runs /install-statusline or asks to install/enable the statusline plugin.
---

# Install statusline

This skill prompts the user for a color theme and symbol style, then runs the bundled installer with the chosen options. The installer is deterministic — it copies the script, applies the chosen theme/style to it, patches `settings.json` (preserving other keys), creates `~/.claude/settings.json` if it doesn't exist, and aborts on malformed settings without overwriting.

## Steps

### 1. Ask the user for preferences

Present the two choices below. **Defaults are `cool-pastel` + `minimal`** — if the user says "just defaults" or doesn't specify, use those without further prompting.

**Color theme** (controls how the `context %` segment is colored as the window fills):
- `current`     — bright gold → orange → coral (loud)
- `cool-pastel` — soft teal → peach → dusty rose (default, calm cool palette)
- `earthy`      — tan → terra cotta → rose red (warm but muted)
- `neutral`     — light gray → peach → coral (gray at low %, only "lights up" when filling)

**Symbol style** (controls dir / branch / separator glyphs):
- `minimal` — `›` dir · `⎇` branch · `·` separator (default, minimal punctuation)
- `sharp`   — `❯` dir · `⊢` branch · `│` separator (vertical bars, dev-tool aesthetic)
- `soft`    — `»` dir · `↳` branch · `•` separator (rounder shapes)

Accept short answers like just the theme name, or "default", or "1 / 2 / 3" matching the order presented.

### 2. Detect OS and run the installer

Claude Code automatically adds the plugin's `bin/` directory to `PATH`, so call by name:

- **Windows** (PowerShell):
  ```powershell
  install.ps1 -Theme <theme> -Style <style>
  ```
- **macOS / Linux**:
  ```bash
  install.sh --theme <theme> --style <style>
  ```

### 3. Report and restart

Show the installer's output to the user verbatim — it lists exactly which files were touched. Then tell them to **restart Claude Code**. The statusline command in `settings.json` is read at startup; it won't take effect in the current session.

## Prerequisites

- **macOS / Linux**: `jq` must be installed. The installer aborts with installation hints (`brew install jq` / `apt install jq` / `dnf install jq`) if missing.
- **Windows**: PowerShell 5.1+ (built-in, no extra deps).

## What the installer does

- Copies `<plugin>/scripts/statusline.{ps1,sh}` to `~/.claude/`
- Rewrites the `THEME` and `STYLE` variables at the top of the copied script to the chosen values
- Adds or replaces the `statusLine` key in `~/.claude/settings.json` (other keys preserved)
- On Unix: marks the script executable

## What it does NOT do

- Does not install `jq` for you (auto-install across distros is brittle)
- Does not modify any other settings keys
- Does not create the `cost-tracker/` directory — the statusline script does that on first run

## Changing theme/style later

The user can re-run the installer with different flags, or just edit the `THEME` / `STYLE` variables at the top of `~/.claude/statusline.{ps1,sh}` directly.

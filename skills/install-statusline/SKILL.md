---
name: install-statusline
description: Install the claude-statusline-pretty bundled script and patch ~/.claude/settings.json. Lets the user pick a color theme and symbol style. Use when the user runs /install-statusline or asks to install/enable the statusline plugin.
---

# Install statusline

This skill prompts the user for a color theme and symbol style, then runs the bundled installer with the chosen options. The installer is deterministic — it copies the script, applies the chosen theme/style to it, patches `settings.json` (preserving other keys), creates `~/.claude/settings.json` if it doesn't exist, and aborts on malformed settings without overwriting.

## Steps

### 1. Ask the user for preferences

Present the two choices below. **Defaults are `cool-pastel` + `minimal`** — if the user says "just defaults" or doesn't specify, use those without further prompting.

**Color theme** (controls the *full palette* — every element on the line gets its color from the theme):
- `current`     — bright cyan/green/magenta (loud, classic terminal)
- `cool-pastel` — lilac/sky-blue/mint/lavender (default, calm cool palette)
- `earthy`      — beige/sage/olive/rust/rose (warm, muted earth tones)
- `neutral`     — mostly grayscale; warning colors only show on context pressure
- `custom`      — read a 13-color palette from `~/.claude/statusline-theme.json` at runtime (script seeds a starter file from `cool-pastel` if missing)

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
- If `--theme custom` and `~/.claude/statusline-theme.json` doesn't already exist, seeds it from the bundled `cool-pastel` example so the user has a file to edit

## What it does NOT do

- Does not install `jq` for you (auto-install across distros is brittle)
- Does not modify any other settings keys
- Does not create the `cost-tracker/` directory — the statusline script does that on first run

## Changing theme/style later

The user can re-run the installer with different flags, or just edit the `THEME` / `STYLE` variables at the top of `~/.claude/statusline.{ps1,sh}` directly.

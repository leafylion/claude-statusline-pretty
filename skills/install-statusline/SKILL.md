---
name: install-statusline
description: Install the claude-statusline-pretty bundled script and patch ~/.claude/settings.json. Use when the user runs /install-statusline or asks to install/enable the statusline plugin.
---

# Install statusline

This skill runs the bundled installer. The installer is deterministic — it copies the script, patches `settings.json` (preserving other keys), creates `~/.claude/settings.json` if it doesn't exist, and aborts on malformed settings without overwriting.

## Steps

1. **Detect OS** and run the matching command. Claude Code automatically adds the plugin's `bin/` directory to `PATH`, so call by name:

   - **Windows** (PowerShell): `install.ps1`
   - **macOS / Linux**: `install.sh`

2. **Show the installer's output to the user** verbatim — it lists exactly which files were touched.

3. **Tell the user to restart Claude Code.** The statusline command in `settings.json` is read at startup; it won't take effect in the current session.

## Prerequisites

- **macOS / Linux**: `jq` must be installed. The installer aborts with installation hints (`brew install jq` / `apt install jq` / `dnf install jq`) if missing.
- **Windows**: PowerShell 5.1+ (built-in, no extra deps).

## What the installer does

- Copies `<plugin>/scripts/statusline.{ps1,sh}` to `~/.claude/`
- Adds or replaces the `statusLine` key in `~/.claude/settings.json` (other keys preserved)
- On Unix: marks the script executable

## What it does NOT do

- Does not install `jq` for you (auto-install across distros is brittle)
- Does not modify any other settings keys
- Does not create the `cost-tracker/` directory — the statusline script does that on first run

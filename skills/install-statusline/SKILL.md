---
name: install-statusline
description: Install the pretty statusline by copying the bundled script to ~/.claude/ and patching ~/.claude/settings.json. Use when the user runs /install-statusline or asks to install/enable the statusline plugin.
---

# Install statusline

This skill installs the pretty statusline shipped with this plugin.

## Steps

1. **Detect the OS** — check `process.platform` (or `$env:OS` / `uname`):
   - Windows → use `statusline.ps1`
   - macOS / Linux → use `statusline.sh`

2. **Locate the bundled script** — it lives in this plugin under `scripts/`. The plugin directory is available via the `${CLAUDE_PLUGIN_ROOT}` environment variable when the skill runs, so the source path is:
   - Windows: `${CLAUDE_PLUGIN_ROOT}/scripts/statusline.ps1`
   - Unix:    `${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh`

3. **Copy the script** to `~/.claude/`:
   - Windows target: `$env:USERPROFILE\.claude\statusline.ps1`
   - Unix target:    `$HOME/.claude/statusline.sh` — and `chmod +x` it

4. **Patch `~/.claude/settings.json`** — read the existing JSON (create `{}` if missing), then add or overwrite the `statusLine` key:

   **Windows:**
   ```json
   "statusLine": {
     "type": "command",
     "command": "powershell -NoProfile -NonInteractive -Command \"& 'C:\\Users\\<USERNAME>\\.claude\\statusline.ps1'\""
   }
   ```
   Substitute `<USERNAME>` with the actual Windows username at install time (read from `$env:USERNAME`).

   **macOS / Linux:**
   ```json
   "statusLine": {
     "type": "command",
     "command": "$HOME/.claude/statusline.sh"
   }
   ```

5. **Check dependencies:**
   - On macOS / Linux: warn if `jq` is not on `$PATH`. Suggest `brew install jq` (mac) or the appropriate package manager (linux).
   - On Windows: PowerShell 5.1+ is built-in, no extra deps.

6. **Confirm** with the user that the install succeeded and remind them to start a new Claude Code session to see the statusline.

## Notes

- Preserve any other keys in `settings.json` — only the `statusLine` key should be replaced.
- If `settings.json` has malformed JSON, abort and tell the user instead of overwriting it.
- The cost tracker lives at `~/.claude/cost-tracker/` and is created automatically on first run; nothing to install for it.

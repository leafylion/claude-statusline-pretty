#!/usr/bin/env bash
# Installer for claude-statusline-pretty (macOS / Linux).
# Copies the bundled statusline.sh to ~/.claude/ and patches ~/.claude/settings.json.

set -euo pipefail

QUIET=""
[ "${1:-}" = "--quiet" ] && QUIET=1
log() { [ -n "$QUIET" ] || echo "$@"; }

# Locate plugin root (parent of bin/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
SRC="$PLUGIN_ROOT/scripts/statusline.sh"

if [ ! -f "$SRC" ]; then
    echo "Error: cannot find bundled script at $SRC" >&2
    exit 1
fi

# Check jq (required for the statusline script itself)
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    echo "  macOS:   brew install jq" >&2
    echo "  Debian:  sudo apt install jq" >&2
    echo "  Fedora:  sudo dnf install jq" >&2
    exit 1
fi

CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# Copy script
DST="$CLAUDE_DIR/statusline.sh"
cp "$SRC" "$DST"
chmod +x "$DST"
log "[ok] Copied statusline.sh -> $DST"

# Patch settings.json
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
    if ! jq empty "$SETTINGS" 2>/dev/null; then
        echo "Error: $SETTINGS is malformed JSON. Fix it and re-run install." >&2
        exit 1
    fi
    jq --arg cmd "$DST" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
else
    cat > "$SETTINGS" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "$DST"
  }
}
EOF
fi
log "[ok] Updated $SETTINGS"

log ''
log 'Done. Restart Claude Code to see the new statusline.'

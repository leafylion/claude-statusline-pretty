#!/usr/bin/env bash
# Installer for claude-statusline-pretty (macOS / Linux).
# Copies the bundled statusline.sh to ~/.claude/, applies the chosen theme/style,
# and patches ~/.claude/settings.json (preserves other keys).

set -euo pipefail

THEME='cool-pastel'
STYLE='minimal'
QUIET=""

while [ $# -gt 0 ]; do
    case "$1" in
        --theme) THEME="${2:-}"; shift 2 ;;
        --style) STYLE="${2:-}"; shift 2 ;;
        --quiet) QUIET=1; shift ;;
        --help|-h)
            echo "Usage: install.sh [--theme <current|cool-pastel|earthy|neutral>] [--style <minimal|sharp|soft>] [--quiet]"
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

case "$THEME" in
    current|cool-pastel|earthy|neutral) ;;
    *) echo "Invalid theme: $THEME (valid: current, cool-pastel, earthy, neutral)" >&2; exit 1 ;;
esac

case "$STYLE" in
    minimal|sharp|soft) ;;
    *) echo "Invalid style: $STYLE (valid: minimal, sharp, soft)" >&2; exit 1 ;;
esac

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

# Apply theme/style by rewriting only the assigned value on the THEME/STYLE lines.
# Using sub() (not full-line replace) preserves any trailing comments the user
# may have added. awk is portable across BSD (mac) and GNU (linux) — sed -i is not.
awk -v theme="$THEME" -v style="$STYLE" '
    /^THEME=/ { sub(/THEME=\047[^\047]*\047/, "THEME=\047" theme "\047"); print; next }
    /^STYLE=/ { sub(/STYLE=\047[^\047]*\047/, "STYLE=\047" style "\047"); print; next }
    { print }
' "$DST" > "$DST.tmp" && mv "$DST.tmp" "$DST"
chmod +x "$DST"
log "[ok] Copied statusline.sh -> $DST (theme=$THEME, style=$STYLE)"

# Patch settings.json
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
    if ! jq empty "$SETTINGS" 2>/dev/null; then
        cat >&2 <<EOF
Error: cannot parse $SETTINGS as strict JSON.
The installer requires standard JSON — comments (// or /* */) and trailing commas
are not supported. If your settings.json contains either, remove them and re-run.
EOF
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

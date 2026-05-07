#!/usr/bin/env bash
# Pretty 2-line statusline for Claude Code (macOS / Linux).
# Requires: jq

set -u

ESC=$'\033'
fg() { printf '%s[38;5;%sm' "$ESC" "$1"; }
RESET="${ESC}[0m"

# --- Theme picker ---
# Change THEME to one of: 'current', 'cool-pastel', 'earthy', 'neutral', 'custom'
# When set to 'custom', the script reads ~/.claude/statusline-theme.json for a 13-color palette.
THEME='neutral'

# --- Symbol style picker ---
# Change STYLE to one of: 'minimal', 'sharp', 'soft'
STYLE='minimal'

# Default to cool-pastel (used as fallback for custom-theme errors)
T_MODEL=183; T_SESSION=247; T_DIR=81; T_BRANCH=121; T_EFFORT=117
T_CTX_OK=152; T_CTX_WN=215; T_CTX_ER=174
T_CACHE=80; T_DURATION=244; T_COST=147; T_TOTAL=219; T_SEP=238

case "$THEME" in
    current)
        T_MODEL=51;  T_SESSION=247; T_DIR=39;  T_BRANCH=46;  T_EFFORT=220
        T_CTX_OK=220; T_CTX_WN=208; T_CTX_ER=203
        T_CACHE=82;  T_DURATION=244; T_COST=207; T_TOTAL=197; T_SEP=238
        ;;
    cool-pastel)
        T_MODEL=183; T_SESSION=247; T_DIR=81;  T_BRANCH=121; T_EFFORT=117
        T_CTX_OK=152; T_CTX_WN=215; T_CTX_ER=174
        T_CACHE=80;  T_DURATION=244; T_COST=147; T_TOTAL=219; T_SEP=238
        ;;
    earthy)
        T_MODEL=222; T_SESSION=138; T_DIR=108; T_BRANCH=107; T_EFFORT=179
        T_CTX_OK=144; T_CTX_WN=173; T_CTX_ER=167
        T_CACHE=137; T_DURATION=242; T_COST=178; T_TOTAL=168; T_SEP=238
        ;;
    neutral)
        T_MODEL=254; T_SESSION=245; T_DIR=250; T_BRANCH=248; T_EFFORT=244
        T_CTX_OK=248; T_CTX_WN=215; T_CTX_ER=203
        T_CACHE=250; T_DURATION=240; T_COST=246; T_TOTAL=252; T_SEP=238
        ;;
    custom)
        customPath="$HOME/.claude/statusline-theme.json"
        if [ -f "$customPath" ] && command -v jq >/dev/null 2>&1; then
            # Read all 13 keys; if any is missing, leave defaults (cool-pastel) in place.
            _all=$(jq -r '
                if (.model and .session and .dir and .branch and .effort
                    and .ctx_ok and .ctx_wn and .ctx_er and .cache
                    and .duration and .cost and .total and .sep)
                then "\(.model) \(.session) \(.dir) \(.branch) \(.effort) \(.ctx_ok) \(.ctx_wn) \(.ctx_er) \(.cache) \(.duration) \(.cost) \(.total) \(.sep)"
                else "" end
            ' "$customPath" 2>/dev/null)
            if [ -n "$_all" ]; then
                read -r T_MODEL T_SESSION T_DIR T_BRANCH T_EFFORT T_CTX_OK T_CTX_WN T_CTX_ER T_CACHE T_DURATION T_COST T_TOTAL T_SEP <<EOF
$_all
EOF
            fi
        fi
        ;;
esac

case "$STYLE" in
    minimal) SYM_DIR='›'; SYM_BRANCH='⎇'; SYM_SEP='·' ;;
    sharp)   SYM_DIR='❯'; SYM_BRANCH='⊢'; SYM_SEP='│' ;;
    soft)    SYM_DIR='»'; SYM_BRANCH='↳'; SYM_SEP='•' ;;
    *)       SYM_DIR='›'; SYM_BRANCH='⎇'; SYM_SEP='·' ;;
esac

C_MODEL=$(fg $T_MODEL)
C_SESSION=$(fg $T_SESSION)
C_DIR=$(fg $T_DIR)
C_BRANCH=$(fg $T_BRANCH)
C_EFFORT=$(fg $T_EFFORT)
C_CTX_OK=$(fg $T_CTX_OK)
C_CTX_WN=$(fg $T_CTX_WN)
C_CTX_ER=$(fg $T_CTX_ER)
C_CACHE=$(fg $T_CACHE)
C_DURATION=$(fg $T_DURATION)
C_COST=$(fg $T_COST)
C_TOTAL=$(fg $T_TOTAL)
C_SEP=$(fg $T_SEP)

SEP_DOT="${C_SEP}${SYM_SEP}${RESET}"
SEP=" ${SEP_DOT} "

input=$(cat)
if [ -z "${input// }" ]; then
    printf '%sClaude%s' "$C_MODEL" "$RESET"
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    printf '%sClaude%s (install jq for full statusline)' "$C_MODEL" "$RESET"
    exit 0
fi

J() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

raw_model=$(J '.model.display_name // "Claude"')
model=$(printf '%s' "$raw_model" | sed -E 's/[[:space:]]*\([^)]*\)//g')
dir=$(J '.workspace.current_dir // .cwd // ""')
sessionId=$(J '.session_id // ""')
sessionCost=$(J '.cost.total_cost_usd // 0')
sessionName=$(J '.session_name // ""')
ctxPct=$(J '.context_window.used_percentage // 0')
effort=$(J '.effort.level // ""')
durationMs=$(J '.cost.total_duration_ms // 0')
inputTok=$(J '.context_window.current_usage.input_tokens // 0')
cacheCreate=$(J '.context_window.current_usage.cache_creation_input_tokens // 0')
cacheRead=$(J '.context_window.current_usage.cache_read_input_tokens // 0')

dirName=""
[ -n "$dir" ] && dirName=$(basename "$dir")

format_duration() {
    local ms=$1
    local total_sec=$(( ms / 1000 ))
    if [ "$total_sec" -lt 60 ]; then
        echo "${total_sec}s"
    elif [ "$total_sec" -lt 3600 ]; then
        echo "$(( total_sec / 60 ))m $(( total_sec % 60 ))s"
    else
        echo "$(( total_sec / 3600 ))h $(( (total_sec % 3600) / 60 ))m"
    fi
}

# --- Line 1: identity / location ---
line1="${C_MODEL}${model}${RESET}"

if [ -n "$sessionName" ] && [ "$sessionName" != "null" ]; then
    # Strip control characters / ANSI escapes to prevent terminal injection
    sessionName=$(printf '%s' "$sessionName" | tr -d '\000-\037\177')
    if [ "${#sessionName}" -gt 40 ]; then
        sessionName="${sessionName:0:37}..."
    fi
    line1="${line1}${SEP}${C_SESSION}\"${sessionName}\"${RESET}"
fi

if [ -n "$dirName" ]; then
    line1="${line1}${SEP}${C_DIR}${SYM_DIR} ${dirName}${RESET}"
fi

if [ -n "$dir" ] && [ -d "$dir" ]; then
    branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null || true)
    if [ -n "$branch" ]; then
        line1="${line1}${SEP}${C_BRANCH}${SYM_BRANCH} ${branch}${RESET}"
    fi
fi

# --- Line 2: session metrics ---
line2_parts=()

if [ -n "$effort" ] && [ "$effort" != "null" ]; then
    line2_parts+=("${C_EFFORT}effort:${effort}${RESET}")
fi

ctx_int=$(printf '%.0f' "$ctxPct" 2>/dev/null || echo 0)
if [ "$ctx_int" -ge 80 ]; then
    ctx_color="$C_CTX_ER"
elif [ "$ctx_int" -ge 50 ]; then
    ctx_color="$C_CTX_WN"
else
    ctx_color="$C_CTX_OK"
fi
line2_parts+=("${ctx_color}context ${ctx_int}%${RESET}")

cache_total=$(( inputTok + cacheCreate + cacheRead ))
if [ "$cache_total" -gt 0 ]; then
    cache_pct=$(( cacheRead * 100 / cache_total ))
    line2_parts+=("${C_CACHE}cache ${cache_pct}%${RESET}")
fi

if [ "$durationMs" -gt 0 ]; then
    line2_parts+=("${C_DURATION}$(format_duration "$durationMs")${RESET}")
fi

# --- Cost tracking (per-model, one file per session) ---
trackerDir="$HOME/.claude/cost-tracker"
mkdir -p "$trackerDir" 2>/dev/null || true

# Migrate legacy single-file tracker if present.
# jq emits one entry per line with key + value as JSON; we read the key safely
# (filename-validated) and write the value through jq's --argjson.
legacyPath="$HOME/.claude/cost-tracker.json"
if [ -f "$legacyPath" ]; then
    while IFS= read -r entry; do
        [ -z "$entry" ] && continue
        key=$(printf '%s' "$entry" | jq -r '.key' 2>/dev/null)
        case "$key" in
            *[!A-Za-z0-9_-]*|"") continue ;;
        esac
        perFile="$trackerDir/${key}.json"
        if [ ! -f "$perFile" ]; then
            printf '%s' "$entry" | jq '.value' > "$perFile" 2>/dev/null || true
        fi
    done < <(jq -c 'to_entries[]' "$legacyPath" 2>/dev/null)
    rm -f "$legacyPath"
fi

# Sanitize session_id — must be filename-safe (no path traversal)
case "$sessionId" in
    *[!A-Za-z0-9_-]*|"") sessionId="" ;;
esac

if [ -n "$sessionId" ] && [ "$sessionId" != "null" ]; then
    ownPath="$trackerDir/${sessionId}.json"
    if [ -f "$ownPath" ]; then
        last_model=$(jq -r '.last_model // ""' "$ownPath")
        last_cost=$(jq -r '.last_cost // 0' "$ownPath")
    else
        last_model="$model"
        last_cost=0
        jq -n --arg m "$model" '{last_model: $m, last_cost: 0, model_costs: {}}' > "$ownPath"
    fi

    delta=$(awk -v c="$sessionCost" -v l="$last_cost" 'BEGIN { printf "%.10f", c - l }')
    delta_pos=$(awk -v d="$delta" 'BEGIN { print (d > 0) ? 1 : 0 }')

    if [ "$delta_pos" = "1" ]; then
        charged=$last_model
        [ -z "$charged" ] && charged="$model"
        jq --arg model "$model" \
           --arg charged "$charged" \
           --argjson cost "$sessionCost" \
           --argjson delta "$delta" \
           '.last_model = $model | .last_cost = $cost | .model_costs[$charged] = ((.model_costs[$charged] // 0) + $delta)' \
           "$ownPath" > "${ownPath}.tmp" && mv "${ownPath}.tmp" "$ownPath"
    else
        jq --arg model "$model" --argjson cost "$sessionCost" \
           '.last_model = $model | .last_cost = $cost' \
           "$ownPath" > "${ownPath}.tmp" && mv "${ownPath}.tmp" "$ownPath"
    fi
fi

# Aggregate per-model totals across all session files
breakdown_json='{}'
if compgen -G "$trackerDir/*.json" > /dev/null; then
    breakdown_json=$(jq -s 'reduce .[].model_costs as $mc ({}; reduce ($mc | keys[]) as $k (.; .[$k] = (.[$k] // 0) + $mc[$k]))' "$trackerDir"/*.json 2>/dev/null || echo '{}')
fi

# Build sorted breakdown string
breakdown=$(printf '%s' "$breakdown_json" | jq -r 'to_entries | sort_by(-.value) | map("\(.key) $\(.value | . * 100 | round / 100 | tostring)") | join(" / ")' 2>/dev/null)
grand_total=$(printf '%s' "$breakdown_json" | jq -r '[.[]] | add // 0' 2>/dev/null)

if [ -n "$breakdown" ] && [ "$breakdown" != "" ]; then
    # Recolor the / separator to be subtle
    colored=$(printf '%s' "$breakdown" | sed "s| / | ${SEP_DOT} ${C_COST}|g")
    line2_parts+=("${C_COST}${colored}${RESET}")
    line2_parts+=("${C_TOTAL}\$$(printf '%.2f' "$grand_total") total${RESET}")
fi

# Join line2 parts with separators
line2=""
first=1
for part in "${line2_parts[@]}"; do
    if [ $first -eq 1 ]; then
        line2="$part"
        first=0
    else
        line2="${line2}${SEP}${part}"
    fi
done

printf '%s\n%s' "$line1" "$line2"

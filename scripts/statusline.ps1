[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ESC = [char]27

function fg($n) { "$ESC[38;5;${n}m" }
$RESET = "$ESC[0m"

# --- Theme picker ---
# Change $THEME to one of: 'current', 'cool-pastel', 'earthy', 'neutral'
$THEME = 'neutral'

# --- Symbol style picker ---
# Change $STYLE to one of: 'minimal', 'sharp', 'soft'
$STYLE = 'minimal'

$THEMES = @{
    'current'     = @{ ok = 220; wn = 208; er = 203 }  # gold / orange / coral
    'cool-pastel' = @{ ok = 152; wn = 215; er = 174 }  # teal / peach / dusty rose
    'earthy'      = @{ ok = 144; wn = 173; er = 167 }  # tan / terra cotta / rose red
    'neutral'     = @{ ok = 250; wn = 215; er = 203 }  # light gray / peach / coral
}
$picked = $THEMES[$THEME]; if (-not $picked) { $picked = $THEMES['current'] }

$STYLES = @{
    'minimal' = @{ dir = [char]0x203A; branch = [char]0x2387; sep = [char]0x00B7 }   # > -|- .
    'sharp'   = @{ dir = [char]0x276F; branch = [char]0x22A2; sep = [char]0x2502 }   # > |- |
    'soft'    = @{ dir = [char]0x00BB; branch = [char]0x21B3; sep = [char]0x2022 }   # >> -> *
}
$sym = $STYLES[$STYLE]; if (-not $sym) { $sym = $STYLES['minimal'] }

# Color palette (256-color)
$C_MODEL    = fg 183             # soft lilac
$C_SESSION  = fg 247             # light gray
$C_DIR      = fg 81              # sky blue
$C_BRANCH   = fg 121             # mint green
$C_EFFORT   = fg 117             # light blue
$C_CTX_OK   = fg $picked.ok
$C_CTX_WN   = fg $picked.wn
$C_CTX_ER   = fg $picked.er
$C_CACHE    = fg 180             # soft amber
$C_DURATION = fg 244             # mid gray
$C_COST     = fg 147             # lavender
$C_TOTAL    = fg 219             # bright pink
$C_SEP      = fg 238             # subtle gray

$SEP_DOT = "${C_SEP}$($sym.sep)${RESET}"
$SEP     = " ${SEP_DOT} "

function FormatDuration($ms) {
    if (-not $ms) { return $null }
    $totalSec = [int]([double]$ms / 1000)
    if ($totalSec -lt 60) { return "${totalSec}s" }
    $h = [int]($totalSec / 3600)
    $m = [int](($totalSec % 3600) / 60)
    $s = $totalSec % 60
    if ($h -gt 0) { return "${h}h ${m}m" }
    return "${m}m ${s}s"
}

# Read stdin
$lines = @()
try {
    while ($null -ne ($line = [Console]::In.ReadLine())) { $lines += $line }
} catch {}
$raw = $lines -join "`n"

if (-not $raw.Trim()) {
    [Console]::Write("${C_MODEL}Claude${RESET}")
    exit 0
}

try { $data = $raw | ConvertFrom-Json }
catch {
    [Console]::Write("${C_MODEL}Claude${RESET}")
    exit 0
}

$model = if ($data.model.display_name) { $data.model.display_name -replace '\s*\(.*?\)', '' } else { 'Claude' }
$dir = if ($data.workspace.current_dir) { $data.workspace.current_dir }
       elseif ($data.cwd) { $data.cwd }
       else { '' }
$dirName = if ($dir) { Split-Path $dir -Leaf } else { '' }

# --- Line 1 parts: identity / location ---
$line1 = @()
$line1 += "${C_MODEL}${model}${RESET}"

if ($data.session_name) {
    # Strip control characters / ANSI escapes to prevent terminal injection
    $name = $data.session_name -replace '[\x00-\x1F\x7F]', ''
    if ($name.Length -gt 40) { $name = $name.Substring(0, 37) + '...' }
    $line1 += "${C_SESSION}`"$name`"${RESET}"
}

if ($dirName) { $line1 += "${C_DIR}$($sym.dir) $dirName${RESET}" }

if ($dir) {
    $b = (git -C "$dir" --no-optional-locks branch --show-current 2>$null) | Select-Object -First 1
    if ($LASTEXITCODE -eq 0 -and $b) {
        $line1 += "${C_BRANCH}$($sym.branch) $b${RESET}"
    }
}

# --- Line 2 parts: session metrics ---
$line2 = @()

# Effort level
if ($data.effort.level) {
    $line2 += "${C_EFFORT}effort:$($data.effort.level)${RESET}"
}

# Context window
$usedPct = $data.context_window.used_percentage
if ($null -ne $usedPct) {
    $pct = [int][Math]::Round($usedPct)
    $ctxColor = if ($pct -ge 80) { $C_CTX_ER } elseif ($pct -ge 50) { $C_CTX_WN } else { $C_CTX_OK }
    $line2 += "${ctxColor}context ${pct}%${RESET}"
}

# Cache hit ratio (from most recent API request)
$cu = $data.context_window.current_usage
if ($cu) {
    $cacheTotal = [double]$cu.input_tokens + [double]$cu.cache_creation_input_tokens + [double]$cu.cache_read_input_tokens
    if ($cacheTotal -gt 0) {
        $cacheHit = [int][Math]::Round(([double]$cu.cache_read_input_tokens / $cacheTotal) * 100)
        $line2 += "${C_CACHE}cache ${cacheHit}%${RESET}"
    }
}

# Duration
$durStr = FormatDuration $data.cost.total_duration_ms
if ($durStr) {
    $line2 += "${C_DURATION}${durStr}${RESET}"
}

# --- Cost tracking (per-model, one file per session — race-free) ---
$sessionId    = $data.session_id
$sessionCost  = $data.cost.total_cost_usd
$currentModel = $model

# Sanitize session_id — must be filename-safe (no path traversal)
if ($sessionId -and $sessionId -notmatch '^[A-Za-z0-9_-]+$') {
    $sessionId = $null
}

$trackerDir = "$env:USERPROFILE\.claude\cost-tracker"
if (-not (Test-Path $trackerDir)) {
    try { New-Item -ItemType Directory -Path $trackerDir -Force | Out-Null } catch {}
}

# One-time migration from old single-file tracker
$legacyPath = "$env:USERPROFILE\.claude\cost-tracker.json"
if (Test-Path $legacyPath) {
    try {
        $legacy = Get-Content $legacyPath -Raw | ConvertFrom-Json
        $legacy.PSObject.Properties | ForEach-Object {
            $perFile = Join-Path $trackerDir ("$($_.Name).json")
            if (-not (Test-Path $perFile)) {
                $_.Value | ConvertTo-Json -Depth 4 | Set-Content $perFile -Encoding utf8 -Force
            }
        }
        Remove-Item $legacyPath -Force
    } catch {}
}

# Update only THIS session's file
$ownPath = Join-Path $trackerDir "$sessionId.json"
$own = @{ last_model = $currentModel; last_cost = 0.0; model_costs = @{} }

if ($sessionId -and (Test-Path $ownPath)) {
    try {
        $loaded = Get-Content $ownPath -Raw | ConvertFrom-Json
        $mc = @{}
        if ($loaded.model_costs) {
            $loaded.model_costs.PSObject.Properties | ForEach-Object { $mc[$_.Name] = [double]$_.Value }
        }
        $own = @{
            last_model  = [string]$loaded.last_model
            last_cost   = [double]$loaded.last_cost
            model_costs = $mc
        }
    } catch {}
}

if ($null -ne $sessionCost -and $sessionId) {
    $delta = [double]$sessionCost - $own.last_cost
    if ($delta -gt 0) {
        $chargedModel = if ($own.last_model) { $own.last_model } else { $currentModel }
        $own.model_costs[$chargedModel] = [double]($own.model_costs[$chargedModel]) + $delta
    }
    $own.last_model = $currentModel
    $own.last_cost  = [double]$sessionCost

    try { $own | ConvertTo-Json -Depth 4 | Set-Content $ownPath -Encoding utf8 -Force } catch {}
}

# Aggregate per-model totals by reading every session file
$byModel = @{}
Get-ChildItem -Path $trackerDir -Filter '*.json' -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $entry = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if ($entry.model_costs) {
            $entry.model_costs.PSObject.Properties | ForEach-Object {
                $byModel[$_.Name] = [double]($byModel[$_.Name]) + [double]$_.Value
            }
        }
    } catch {}
}

if ($byModel.Count -gt 0) {
    $grandTotal = ($byModel.Values | Measure-Object -Sum).Sum
    $modelBreakdown = ($byModel.GetEnumerator() | Sort-Object Value -Descending |
        ForEach-Object { "$($_.Key) `$$($_.Value.ToString('F2'))" }) -join " ${SEP_DOT} "
    $line2 += "${C_COST}${modelBreakdown}${RESET}"
    $line2 += "${C_TOTAL}`$$($grandTotal.ToString('F2')) total${RESET}"
}

# --- Render: 2 lines ---
$out = ($line1 -join $SEP) + "`n" + ($line2 -join $SEP)
[Console]::Write($out)

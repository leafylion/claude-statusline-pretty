# Installer for claude-statusline-pretty (Windows)
# Copies the bundled statusline.ps1 to ~/.claude/, applies the chosen theme/style,
# and patches ~/.claude/settings.json (preserves other keys).

[CmdletBinding()]
param(
    [ValidateSet('current','cool-pastel','earthy','neutral','custom')]
    [string]$Theme = 'cool-pastel',
    [ValidateSet('minimal','sharp','soft')]
    [string]$Style = 'minimal',
    [switch]$InstallCcusage,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

function Log($msg) { if (-not $Quiet) { Write-Host $msg } }

# Locate plugin root (parent of bin/)
$pluginRoot = Split-Path -Parent $PSScriptRoot
$src = Join-Path $pluginRoot 'scripts\statusline.ps1'

if (-not (Test-Path $src)) {
    Write-Error "Cannot find bundled script at $src"
    exit 1
}

# Ensure ~/.claude exists
$claudeDir = Join-Path $env:USERPROFILE '.claude'
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

# Copy script
$dst = Join-Path $claudeDir 'statusline.ps1'
Copy-Item $src $dst -Force

# Apply chosen theme / style by rewriting the variable lines at the top
$content = Get-Content $dst -Raw
$content = $content -replace "(?m)^\s*\`$THEME\s*=\s*'[^']*'", "`$THEME = '$Theme'"
$content = $content -replace "(?m)^\s*\`$STYLE\s*=\s*'[^']*'", "`$STYLE = '$Style'"
Set-Content $dst $content -Encoding utf8 -Force
Log "[ok] Copied statusline.ps1 -> $dst (theme=$Theme, style=$Style)"

# When theme=custom, seed ~/.claude/statusline-theme.json from the bundled cool-pastel
# example if the user doesn't already have one. The script reads this at runtime.
if ($Theme -eq 'custom') {
    $themeJsonDst = Join-Path $claudeDir 'statusline-theme.json'
    if (-not (Test-Path $themeJsonDst)) {
        $exampleSrc = Join-Path $pluginRoot 'examples\themes\cool-pastel.json'
        if (Test-Path $exampleSrc) {
            Copy-Item $exampleSrc $themeJsonDst -Force
            Log "[ok] Seeded $themeJsonDst from cool-pastel example — edit to customize."
        }
    } else {
        Log "[ok] Existing $themeJsonDst left unchanged."
    }
}

# Build the command line that settings.json will store
$cmd = "powershell -NoProfile -NonInteractive -Command `"& '$dst'`""

# Read or initialize settings.json
$settingsPath = Join-Path $claudeDir 'settings.json'
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error @"
Cannot parse $settingsPath as strict JSON.
The installer requires standard JSON — comments (// or /* */) and trailing commas
are not supported. If your settings.json contains either, remove them and re-run.
Original error: $($_.Exception.Message)
"@
        exit 1
    }
    if ($settings -isnot [PSCustomObject]) {
        Write-Error "$settingsPath does not contain a JSON object at the top level. Aborting."
        exit 1
    }
} else {
    $settings = [PSCustomObject]@{}
}

# Replace or add statusLine
$statusLine = [PSCustomObject]@{ type = 'command'; command = $cmd }
if ($settings.PSObject.Properties.Name -contains 'statusLine') {
    $settings.statusLine = $statusLine
} else {
    $settings | Add-Member -MemberType NoteProperty -Name 'statusLine' -Value $statusLine
}

# Write settings.json as UTF-8 *without* BOM. PowerShell 5.1's `Set-Content -Encoding utf8`
# emits a BOM, which strict JSON parsers reject. Use the .NET API to write BOM-less UTF-8.
$json = $settings | ConvertTo-Json -Depth 20
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($settingsPath, $json, $utf8NoBom)
Log "[ok] Updated $settingsPath"

# Optional dependency: ccusage powers the monthly cumulative cost readout.
# The statusline works fine without it (the cost line is simply hidden).
function Install-Ccusage {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Log 'Installing ccusage via npm (npm i -g ccusage)...'
        npm install -g ccusage
        if ($LASTEXITCODE -eq 0) { return $true }
        Write-Warning 'npm install failed.'
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Log 'Installing ccusage via winget...'
        winget install --id ryoppippi.ccusage --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) { return $true }
        Write-Warning 'winget install failed.'
    }
    Write-Warning 'Could not install ccusage automatically (need npm or winget). Install manually: npm i -g ccusage'
    return $false
}

if (-not (Get-Command ccusage -ErrorAction SilentlyContinue)) {
    if ($InstallCcusage) {
        [void](Install-Ccusage)
    } elseif (-not $Quiet) {
        Log '[note] ccusage not found - the monthly cost line will be hidden.'
        Log '       Enable it later with: npm i -g ccusage'
    }
}

Log ''
Log 'Done. Restart Claude Code to see the new statusline.'

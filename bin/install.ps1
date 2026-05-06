# Installer for claude-statusline-pretty (Windows)
# Copies the bundled statusline.ps1 to ~/.claude/, applies the chosen theme/style,
# and patches ~/.claude/settings.json (preserves other keys).

[CmdletBinding()]
param(
    [ValidateSet('current','cool-pastel','earthy','neutral')]
    [string]$Theme = 'cool-pastel',
    [ValidateSet('minimal','sharp','soft')]
    [string]$Style = 'minimal',
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

# Build the command line that settings.json will store
$cmd = "powershell -NoProfile -NonInteractive -Command `"& '$dst'`""

# Read or initialize settings.json
$settingsPath = Join-Path $claudeDir 'settings.json'
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Cannot parse $settingsPath as JSON. Fix it and re-run install."
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

$settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding utf8 -Force
Log "[ok] Updated $settingsPath"

Log ''
Log 'Done. Restart Claude Code to see the new statusline.'

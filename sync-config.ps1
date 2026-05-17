# Sync repo wezterm.lua → active config (~/.wezterm.lua)
# Usage:
#   .\sync-config.ps1          — one-shot copy
#   .\sync-config.ps1 -Watch   — watch for changes and auto-sync

param([switch]$Watch)

$Source = Join-Path $PSScriptRoot 'wezterm.lua'
$Target = Join-Path $env:USERPROFILE '.wezterm.lua'

function Sync-Config {
    Copy-Item $Source $Target -Force
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Synced → $Target" -ForegroundColor Green
}

if (-not (Test-Path $Source)) {
    Write-Host "ERROR: $Source not found" -ForegroundColor Red
    exit 1
}

Sync-Config

if ($Watch) {
    Write-Host "Watching $Source for changes... (Ctrl+C to stop)" -ForegroundColor Cyan
    $watcher = [System.IO.FileSystemWatcher]::new((Split-Path $Source), (Split-Path $Source -Leaf))
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
    $watcher.EnableRaisingEvents = $true
    try {
        while ($true) {
            $result = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::Changed, 1000)
            if (-not $result.TimedOut) {
                Start-Sleep -Milliseconds 200
                Sync-Config
            }
        }
    } finally {
        $watcher.Dispose()
    }
}

# ============================================================
#  WezTerm tmux Alternative for Windows
#  One-line install:
#    irm https://raw.githubusercontent.com/Muminur/tmux-alternative-windows/main/install.ps1 | iex
#
#  Switches:
#    -Update       Only refresh config files (skip WezTerm/PS7/Font reinstall)
#    -SkipFont     Skip FiraCode Nerd Font install
#    -SkipPS7      Skip PowerShell 7 install
#    -SkipWezTerm  Skip WezTerm install
#    -SkipZoxide   Skip zoxide smart-cd install
#    -SkipStarship Skip Starship prompt install
#    -DryRun       Print steps without executing
# ============================================================

param(
  [switch]$Update,
  [switch]$SkipFont,
  [switch]$SkipPS7,
  [switch]$SkipWezTerm,
  [switch]$SkipZoxide,
  [switch]$SkipStarship,
  [switch]$DryRun
)

$FontVersion         = '3.3.0'
$MinWezTermBuildDate = '20240203'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Say  { param($msg) Write-Host "  $msg" -ForegroundColor Cyan }
function OK   { param($msg) Write-Host "  OK $msg" -ForegroundColor Green }
function Fail { param($msg) Write-Host "  FAIL $msg" -ForegroundColor Red; exit 1 }
function Warn { param($msg) Write-Host "  WARN $msg" -ForegroundColor Yellow }

function Invoke-Step {
  param([string]$Desc, [scriptblock]$Action)
  if ($DryRun) { Say "[DRY-RUN] $Desc" } else { & $Action }
}

Write-Host ''
Write-Host '  WezTerm tmux Alternative for Windows - Installer' -ForegroundColor Cyan
Write-Host '  https://github.com/Muminur/tmux-alternative-windows' -ForegroundColor DarkCyan
Write-Host ''

# -Update mode: only refresh config/profile, skip binary installs
if ($Update) {
  Say 'Update mode: refreshing config files only'
  $SkipWezTerm  = $true
  $SkipPS7      = $true
  $SkipFont     = $true
  $SkipZoxide   = $true
  $SkipStarship = $true
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Fail "winget not found. Install App Installer from the Microsoft Store first."
}

# 1. WezTerm
if (-not $SkipWezTerm) {
  Say 'Installing WezTerm...'
  Invoke-Step 'winget install WezFurlong.WezTerm' {
    winget install --id WezFurlong.WezTerm --silent --accept-package-agreements --accept-source-agreements --source winget
  }
  OK 'WezTerm installed'
}

# Version check
Invoke-Step 'Check WezTerm version' {
  $wezCmd = Get-Command wezterm -ErrorAction SilentlyContinue
  if ($wezCmd) {
    $verStr = (& wezterm --version 2>&1).ToString()
    if ($verStr -match '(\d{8})') {
      if ([int]$Matches[1] -lt [int]$MinWezTermBuildDate) {
        Warn "WezTerm build $($Matches[1]) is older than recommended $MinWezTermBuildDate"
        Warn 'Upgrade: winget upgrade --id WezFurlong.WezTerm --source winget'
      } else {
        OK "WezTerm version OK: $verStr"
      }
    } else {
      OK "WezTerm found: $verStr"
    }
  } else {
    Warn 'WezTerm not in PATH - restart terminal after install'
    Write-Host '       Location: C:\Program Files\WezTerm\wezterm.exe' -ForegroundColor DarkGray
  }
}

# 2. PowerShell 7
if (-not $SkipPS7) {
  $pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe'
  if (Test-Path $pwsh) {
    OK 'PowerShell 7 already present'
  } else {
    Say 'Installing PowerShell 7...'
    Invoke-Step 'winget install Microsoft.PowerShell' {
      winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements --source winget
    }
    OK 'PowerShell 7 installed'
  }
}

# 3. FiraCode Nerd Font
if (-not $SkipFont) {
  $fontsDir  = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
  $regPath   = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  $checkFont = Join-Path $fontsDir 'FiraCodeNerdFont-Regular.ttf'
  if (Test-Path $checkFont) {
    OK 'FiraCode Nerd Font already installed'
  } else {
    Say "Downloading FiraCode Nerd Font v$FontVersion..."
    Invoke-Step 'Install FiraCode Nerd Font' {
      $zip  = "$env:TEMP\FiraCode.zip"
      $dest = "$env:TEMP\FiraCode"
      $url  = "https://github.com/ryanoasis/nerd-fonts/releases/download/v$FontVersion/FiraCode.zip"
      Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
      Expand-Archive -Path $zip -DestinationPath $dest -Force
      if (-not (Test-Path $fontsDir)) { New-Item -ItemType Directory -Path $fontsDir -Force | Out-Null }
      Get-ChildItem -Path $dest -Filter '*.ttf' | ForEach-Object {
        $dst = Join-Path $fontsDir $_.Name
        Copy-Item $_.FullName $dst -Force
        Set-ItemProperty -Path $regPath -Name ($_.BaseName + ' (TrueType)') -Value $dst -Type String -Force
      }
      Remove-Item $zip, $dest -Recurse -Force -ErrorAction SilentlyContinue
    }
    OK 'FiraCode Nerd Font installed'
  }
}

# 4. WezTerm config
Say 'Installing WezTerm config (neon dark, tmux keys, session save/restore)...'
$cfgDir  = "$env:USERPROFILE\.config\wezterm"
$cfgFile = Join-Path $cfgDir 'wezterm.lua'
$cfgUrl  = 'https://raw.githubusercontent.com/Muminur/tmux-alternative-windows/main/wezterm.lua'
Invoke-Step 'Download wezterm.lua' {
  if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null }
  Invoke-WebRequest -Uri $cfgUrl -OutFile $cfgFile -UseBasicParsing
  Copy-Item $cfgFile "$env:USERPROFILE\.wezterm.lua" -Force
}
OK 'Config saved (also copied to ~/.wezterm.lua)'

# 5. Session directory
Say 'Creating session save directory (~/.wezterm_sessions)...'
Invoke-Step 'Create session directory' {
  $sessDir = "$env:USERPROFILE\.wezterm_sessions"
  if (-not (Test-Path $sessDir)) { New-Item -ItemType Directory -Path $sessDir -Force | Out-Null }
}
OK 'Session directory ready'

# 6. PowerShell profile
Say 'Installing PowerShell profile (Starship/zoxide auto-detect)...'
$profileUrl = 'https://raw.githubusercontent.com/Muminur/tmux-alternative-windows/main/Microsoft.PowerShell_profile.ps1'
Invoke-Step 'Download PS profile' {
  $profileDir = Split-Path $PROFILE -Parent
  if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
  Invoke-WebRequest -Uri $profileUrl -OutFile $PROFILE -UseBasicParsing
}
OK 'PowerShell profile installed'

# 7. zoxide (smart cd)
if (-not $SkipZoxide) {
  if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    OK 'zoxide already installed'
  } else {
    Say 'Installing zoxide (smart directory jumping)...'
    Invoke-Step 'winget install ajeetdsouza.zoxide' {
      winget install --id ajeetdsouza.zoxide --silent --accept-package-agreements --accept-source-agreements --source winget
    }
    OK "zoxide installed - use 'z <dir>' for smart navigation"
  }
}

# 8. Starship prompt
if (-not $SkipStarship) {
  if (Get-Command starship -ErrorAction SilentlyContinue) {
    OK 'Starship prompt already installed'
  } else {
    Say 'Installing Starship prompt (git/language indicators)...'
    Invoke-Step 'winget install Starship.Starship' {
      winget install --id Starship.Starship --silent --accept-package-agreements --accept-source-agreements --source winget
    }
    OK 'Starship installed - auto-activates on next PowerShell start'
  }
}

# Post-install help
Write-Host ''
Write-Host '  Done! Close and reopen WezTerm.' -ForegroundColor Green
Write-Host '  Leader key: CTRL+B (like tmux)' -ForegroundColor Cyan
Write-Host ''
Write-Host '  Panes, Tabs, Layouts:' -ForegroundColor White
Write-Host '    LEADER+|         split right       LEADER+-        split down' -ForegroundColor DarkGray
Write-Host '    LEADER+hjkl      navigate panes    LEADER+c        new tab' -ForegroundColor DarkGray
Write-Host '    LEADER+z         zoom pane toggle  LEADER+e        open selection in editor' -ForegroundColor DarkGray
Write-Host '    LEADER+A         7-pane agent grid' -ForegroundColor DarkGray
Write-Host '    LEADER+Shift+2   2-pane side-by-side (Code + Terminal)' -ForegroundColor DarkGray
Write-Host '    LEADER+Shift+3   3-pane code layout (Editor + Tests + Logs)' -ForegroundColor DarkGray
Write-Host '    LEADER+Ctrl+X    broadcast text to all panes in tab' -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Session Save (tmux-resurrect style):' -ForegroundColor White
Write-Host '    LEADER+Ctrl+S    save session to disk' -ForegroundColor DarkGray
Write-Host '    LEADER+Ctrl+R    restore session from disk' -ForegroundColor DarkGray
Write-Host '    LEADER+Ctrl+N    save as named session' -ForegroundColor DarkGray
Write-Host '    LEADER+Ctrl+L    list and restore a named session' -ForegroundColor DarkGray
Write-Host '    LEADER+Ctrl+D    delete a named session' -ForegroundColor DarkGray
Write-Host '    Auto-saves every 15 minutes automatically' -ForegroundColor DarkGray
Write-Host ''
Write-Host "  Save file: $env:USERPROFILE\.wezterm_sessions\last.json" -ForegroundColor DarkCyan
Write-Host ''
Write-Host '  Flags: -Update  -SkipWezTerm  -SkipPS7  -SkipFont  -SkipZoxide  -SkipStarship  -DryRun' -ForegroundColor DarkGray
Write-Host ''

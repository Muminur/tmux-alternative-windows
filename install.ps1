# ============================================================
#  WezTerm — tmux Alternative for Windows
#  One-line install:
#    irm https://raw.githubusercontent.com/Muminur/tmux-alternative-windows/main/install.ps1 | iex
# ============================================================

param(
  [switch]$SkipFont,
  [switch]$SkipPS7,
  [switch]$SkipWezTerm,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Say  { param($msg) Write-Host "  $msg" -ForegroundColor Cyan }
function OK   { param($msg) Write-Host "  OK $msg" -ForegroundColor Green }
function Fail { param($msg) Write-Host "  FAIL $msg" -ForegroundColor Red; exit 1 }

function Invoke-Step {
  param([string]$Desc, [scriptblock]$Action)
  if ($DryRun) { Say "[DRY-RUN] $Desc" } else { & $Action }
}

Write-Host ""
Write-Host "  WezTerm tmux Alternative for Windows - Installer" -ForegroundColor Cyan
Write-Host "  https://github.com/Muminur/tmux-alternative-windows" -ForegroundColor DarkCyan
Write-Host ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Fail "winget not found. Install 'App Installer' from the Microsoft Store first."
}

# 1. WezTerm
if (-not $SkipWezTerm) {
  Say "Installing WezTerm..."
  Invoke-Step "winget install WezFurlong.WezTerm" {
    winget install --id WezFurlong.WezTerm --silent --accept-package-agreements --accept-source-agreements --source winget
  }
  OK "WezTerm installed"
}

# 2. PowerShell 7
if (-not $SkipPS7) {
  $pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe'
  if (Test-Path $pwsh) {
    OK "PowerShell 7 already present"
  } else {
    Say "Installing PowerShell 7..."
    Invoke-Step "winget install Microsoft.PowerShell" {
      winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements --source winget
    }
    OK "PowerShell 7 installed"
  }
}

# 3. FiraCode Nerd Font
if (-not $SkipFont) {
  $fontsDir  = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
  $regPath   = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  $checkFont = Join-Path $fontsDir 'FiraCodeNerdFont-Regular.ttf'
  if (Test-Path $checkFont) {
    OK "FiraCode Nerd Font already installed"
  } else {
    Say "Downloading FiraCode Nerd Font v3.3.0..."
    Invoke-Step "Install FiraCode Nerd Font" {
      $zip  = "$env:TEMP\FiraCode.zip"
      $dest = "$env:TEMP\FiraCode"
      $url  = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip'
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
    OK "FiraCode Nerd Font installed"
  }
}

# 4. WezTerm config
Say "Installing WezTerm config (neon dark, tmux keys, 7-pane layout)..."
$cfgDir  = "$env:USERPROFILE\.config\wezterm"
$cfgFile = Join-Path $cfgDir 'wezterm.lua'
$cfgUrl  = 'https://raw.githubusercontent.com/Muminur/tmux-alternative-windows/main/wezterm.lua'
Invoke-Step "Download wezterm.lua" {
  if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null }
  Invoke-WebRequest -Uri $cfgUrl -OutFile $cfgFile -UseBasicParsing
  Copy-Item $cfgFile "$env:USERPROFILE\.wezterm.lua" -Force
}
OK "Config saved (also copied to ~/.wezterm.lua)"

# 5. PowerShell profile
Say "Installing neon PowerShell profile..."
$profileUrl = 'https://raw.githubusercontent.com/Muminur/tmux-alternative-windows/main/Microsoft.PowerShell_profile.ps1'
Invoke-Step "Download PS profile" {
  $profileDir = Split-Path $PROFILE -Parent
  if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
  Invoke-WebRequest -Uri $profileUrl -OutFile $PROFILE -UseBasicParsing
}
OK "PowerShell profile installed"

Write-Host ""
Write-Host "  Done! Close and reopen WezTerm." -ForegroundColor Green
Write-Host "  Leader key: CTRL+B (like tmux)" -ForegroundColor Cyan
Write-Host "    LEADER+|  split right    LEADER+A  7-pane agent layout" -ForegroundColor White
Write-Host "    LEADER+-  split down     LEADER+[  copy mode (vim keys)" -ForegroundColor White
Write-Host "    LEADER+hjkl navigate     LEADER+w  workspace switcher" -ForegroundColor White
Write-Host ""

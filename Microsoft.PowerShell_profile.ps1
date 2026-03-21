# ============================================================
#  Neon PowerShell Profile — for WezTerm
#  Repo: https://github.com/Muminur/tmux-alternative-windows
# ============================================================

function prompt {
  $loc   = $ExecutionContext.SessionState.Path.CurrentLocation
  $cyan  = "`e[96m"; $green = "`e[92m"; $reset = "`e[0m"; $bold = "`e[1m"
  $yellow = "`e[93m"
  $branch = ''
  try {
    $b = git rev-parse --abbrev-ref HEAD 2>$null
    if ($b -and $b -ne 'HEAD') { $branch = " ${yellow}($b)${reset}" }
  } catch {}
  "${bold}${cyan}PS${reset} ${green}${loc}${reset}${branch}${cyan}>${reset} "
}

if ($PSVersionTable.PSVersion.Major -ge 7) {
  $PSStyle.Formatting.TableHeader   = "`e[96m"
  $PSStyle.Formatting.ErrorAccent   = "`e[91m"
  $PSStyle.Formatting.Warning       = "`e[93m"
  $PSStyle.Formatting.Verbose       = "`e[95m"
  $PSStyle.Formatting.Debug         = "`e[94m"
  $PSStyle.Progress.Style           = "`e[96m"
  $PSStyle.FileInfo.Directory       = "`e[94;1m"
  $PSStyle.FileInfo.SymbolicLink    = "`e[96m"
  $PSStyle.FileInfo.Executable      = "`e[92m"
}

if (Get-Module -ListAvailable PSReadLine) {
  Set-PSReadLineOption -Colors @{
    Command          = "`e[96m"
    Parameter        = "`e[95m"
    String           = "`e[92m"
    Operator         = "`e[93m"
    Variable         = "`e[97m"
    Number           = "`e[93m"
    Member           = "`e[96m"
    Keyword          = "`e[94m"
    Comment          = "`e[90m"
    Type             = "`e[95m"
    Error            = "`e[91m"
    InlinePrediction = "`e[90m"
  }
  # Smarter predictions: history + plugin (PS7+), fallback to History only
  if ($PSVersionTable.PSVersion.Major -ge 7) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  } else {
    Set-PSReadLineOption -PredictionSource History
  }
  Set-PSReadLineOption -EditMode Windows
  # Dropdown menu completion (Tab shows selectable list instead of cycling)
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

Set-Alias ll Get-ChildItem
Set-Alias g  git

# Navigation shortcuts
function _cd_up1 { Set-Location .. }
function _cd_up2 { Set-Location ../.. }
function _la     { Get-ChildItem -Force @args }
function _gs     { git status @args }

Set-Alias ..  _cd_up1
Set-Alias ... _cd_up2
Set-Alias la  _la
Set-Alias gs  _gs

# WezTerm: The Best tmux Alternative for Windows

> **Replace tmux on Windows** with a GPU-accelerated, natively multiplexing terminal.
> Zero dependencies, one config file, works out of the box on Windows 10/11.

[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?logo=windows&logoColor=white)](https://wezfurlong.org/wezterm/)
[![WezTerm](https://img.shields.io/badge/WezTerm-Nightly-00ffe1)](https://github.com/wezterm/wezterm/releases/tag/nightly)
[![PowerShell 7](https://img.shields.io/badge/PowerShell-7-5391FE?logo=powershell)](https://github.com/PowerShell/PowerShell)
[![FiraCode Nerd Font](https://img.shields.io/badge/Font-FiraCode_Nerd_Font-orange)](https://github.com/ryanoasis/nerd-fonts)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## What Is This?

If you use **tmux on Linux or macOS** and want the same experience on **Windows**, this repo gives you a fully configured [WezTerm](https://wezfurlong.org/wezterm/) setup that matches — and in many ways **exceeds** — tmux.

**No WSL required. No Cygwin. No extra tools. Just one PowerShell command.**

---

## One-Line Install

Open PowerShell (no admin needed) and run:

```powershell
irm https://raw.githubusercontent.com/Muminur/tmux-alternative-windows/main/install.ps1 | iex
```

This installs and configures **everything automatically**:

| Step | Component | What it does |
|------|-----------|-------------|
| 1 | **WezTerm** | GPU-accelerated terminal with built-in multiplexer |
| 2 | **PowerShell 7** | Modern shell with ANSI colour support |
| 3 | **FiraCode Nerd Font** | Programming font with ligatures + Nerd Font glyphs |
| 4 | **wezterm.lua** | Neon dark theme, tmux keybindings, session save/restore |
| 5 | **PS7 profile** | Neon prompt and syntax highlighting |
| 6 | **zoxide** | Smart `cd` replacement with frecency-based directory jumping |
| 7 | **Starship** | Cross-shell prompt with git/language indicators |

> **Requirement:** Windows 10/11 with `winget` (App Installer from the Microsoft Store)

### Install flags

```powershell
# Only refresh config files — skip WezTerm/PS7/Font reinstall
irm .../install.ps1 | iex  # then add -Update

# Skip individual components
install.ps1 -SkipZoxide -SkipStarship -SkipFont

# Preview all steps without executing
install.ps1 -DryRun
```

| Flag | Effect |
|------|--------|
| `-Update` | Re-download `wezterm.lua` and PS profile only |
| `-SkipWezTerm` | Skip WezTerm install |
| `-SkipPS7` | Skip PowerShell 7 install |
| `-SkipFont` | Skip FiraCode Nerd Font install |
| `-SkipZoxide` | Skip zoxide install |
| `-SkipStarship` | Skip Starship install |
| `-DryRun` | Print all steps without executing |

---

## Screenshots

### 2-Pane Workspace — Neon Dark Theme

![WezTerm neon dark 2-pane layout on Windows with cyan divider and status bar](screenshots/wezterm-2pane-neon.png)

*Two PowerShell 7 panes side-by-side. Neon cyan split line. Status bar shows workspace name, active process, and clock. Opens automatically on WezTerm launch.*

### Status Bar Detail

![WezTerm status bar showing main workspace powershell.exe process name and clock](screenshots/wezterm-status-bar.png)

*Right-side status bar: zoom indicator, workspace (cyan), pane count, process name (purple), git branch (yellow), battery, and live clock.*

---

## Why WezTerm Instead of tmux on Windows?

tmux requires WSL or Cygwin on Windows — it is a Linux tool bolted onto Windows. WezTerm is a **native Windows application** built from scratch, with a full terminal multiplexer included.

| Feature | tmux via WSL | WezTerm native |
|---------|:---:|:---:|
| Pane splitting | Yes | Yes |
| Persistent sessions | Yes | Yes |
| Named session save/restore | tmux-resurrect plugin | **Built-in** |
| Auto-save every 15 min | tmux-continuum plugin | **Built-in** |
| Vim-style copy mode | Yes | Yes |
| Named workspaces / sessions | Yes | Yes |
| SSH remote sessions | Yes | Yes |
| GPU-accelerated rendering | No | **Yes** |
| Runs natively on Windows (no WSL) | No | **Yes** |
| Font ligatures | No | **Yes** |
| Lua scripting and automation | No | **Yes** |
| Window transparency and blur | No | **Yes** |
| One-command install | No | **Yes** |
| Broadcast input to all panes | No | **Yes** |
| Zoom indicator in status bar | No | **Yes** |
| Git branch in status bar | No | **Yes** |
| Scrollbar with smart auto-hide | No | **Yes** |

---

## Session Save & Restore (tmux-resurrect / tmux-continuum)

This config implements the same session persistence policy as the popular tmux plugins — and extends it with **named sessions**:

| tmux plugin | WezTerm equivalent |
|------------|-------------------|
| `tmux-resurrect` — manual save/restore | `LEADER + Ctrl+S` / `LEADER + Ctrl+R` |
| `tmux-resurrect` — named sessions | `LEADER + Ctrl+N` / `LEADER + Ctrl+L` |
| `tmux-continuum` — auto-save every 15 min | Built-in auto-save timer |
| `tmux-continuum` — auto-restore on start | Auto-restores on WezTerm startup |

**What is saved:**
- All workspace names (equivalent to tmux sessions)
- Active workspace (restored on next launch)
- All tab titles (equivalent to tmux windows)
- All pane working directories
- Pane layout (split directions reconstructed from saved positions)

**Save files:** `%USERPROFILE%\.wezterm_sessions\`
- `last.json` — most recent auto/manual save
- `prev.json` — backup of previous save (one rollback slot)
- `<name>.json` — named sessions (unlimited slots)

### Named Sessions

Named sessions let you maintain multiple independent workspace layouts — like separate tmux session collections for different projects.

```
LEADER + Ctrl+N  →  prompt for a name, saves to ~/.wezterm_sessions/<name>.json
LEADER + Ctrl+L  →  fuzzy-pick from saved names and restore
LEADER + Ctrl+D  →  fuzzy-pick from saved names and delete
```

### How it works

```
On startup:
  1. Check if ~/.wezterm_sessions/last.json exists → if yes, restore it
     (restores to the active workspace that was open when last saved)
  2. Otherwise → create default 'main' workspace with 2-pane layout

Every 15 minutes:
  Auto-save all workspaces to last.json

LEADER + Ctrl+S:
  Save immediately + show "SAVED" in status bar for 30 seconds

LEADER + Ctrl+R:
  Restore from last.json into current session (adds workspaces)
```

### Status bar indicators

| Badge | Colour | Meaning |
|-------|--------|---------|
| `WAIT` | Magenta | Leader key is active |
| `ZOOM` | Yellow | A pane is zoomed fullscreen |
| `SAVED` | Green | Session was saved (shows for 30 s) |
| Workspace name | Cyan | Current workspace |
| `Np` | Yellow | Number of panes in active tab |
| Process name | Purple | Foreground process |
| Branch name | Yellow | Git branch of active pane's CWD |
| Battery | Green/Red | Battery level |
| Clock | Dim | Day, date, time |

---

## Keybinding Reference

The leader key is **CTRL+B** — same as the tmux default.

### Pane Management

| Keybinding | Action |
|-----------|--------|
| `LEADER + \|` or `%` | Split pane right (vertical divider) |
| `LEADER + -` or `"` | Split pane down (horizontal divider) |
| `LEADER + h/j/k/l` | Navigate panes (vim-style) |
| `LEADER + Arrow keys` | Navigate panes |
| `LEADER + H/J/K/L` | Resize pane by 5 cells |
| `LEADER + z` | Zoom pane fullscreen toggle |
| `LEADER + x` | Close current pane |
| `LEADER + o` | Visual pane picker |
| `LEADER + { / }` | Rotate panes |

### Layouts

| Keybinding | Layout | Use case |
|-----------|--------|----------|
| `LEADER + A` | 7-pane agent grid | Multi-agent (Claude Code etc.) |
| `LEADER + Shift+2` | 2-pane side-by-side | Code + Terminal |
| `LEADER + Shift+3` | 3-pane code layout | Editor + Tests + Logs |

### Broadcast

| Keybinding | Action |
|-----------|--------|
| `LEADER + Ctrl+X` | Prompt for text and send it to **all panes** in the active tab |

Useful with the 7-pane agent layout: run the same setup command across all agents simultaneously.

### Tabs (equivalent to tmux windows)

| Keybinding | Action |
|-----------|--------|
| `LEADER + c` | New tab |
| `LEADER + n / p` | Next / previous tab |
| `LEADER + 1–9` | Switch to tab by number |
| `LEADER + ,` | Rename tab |
| `LEADER + &` | Close tab |

### Workspaces (equivalent to tmux sessions)

| Keybinding | Action |
|-----------|--------|
| `LEADER + w` | Fuzzy workspace switcher |
| `LEADER + s` | Full launcher (workspaces + tabs + apps) |
| `LEADER + W` | Create new named workspace |
| `LEADER + $` | Rename current workspace |
| `LEADER + D` | Connect to SSH domain |
| `LEADER + d` | **Quit WezTerm** — closes the application (save session first with LEADER+Ctrl+S) |

### Session Save & Restore (tmux-resurrect style)

| Keybinding | Action |
|-----------|--------|
| `LEADER + Ctrl+S` | **Save session** — writes all workspaces/tabs/panes to disk |
| `LEADER + Ctrl+R` | **Restore session** — recreates workspaces from last save |
| `LEADER + Ctrl+B` | **Restore backup** — restores from the previous save (`prev.json`) |
| `LEADER + Ctrl+N` | **Save named session** — prompt for a name, save to `<name>.json` |
| `LEADER + Ctrl+L` | **List named sessions** — fuzzy-pick and restore a named session |
| `LEADER + Ctrl+D` | **Delete named session** — fuzzy-pick and delete a named session |

### Copy Mode — Vim Keybindings

Enter with `LEADER + [`, exit with `q` or `Esc`.

| Key | Action |
|-----|--------|
| `h/j/k/l` | Move cursor |
| `w / b / e` | Word forward / backward / end |
| `0 / $` | Start / end of line |
| `g / G` | Top / bottom of scrollback |
| `v` | Character selection |
| `V` | Line selection |
| `Ctrl+v` | Block/rectangle selection |
| `y` | Yank (copy) to clipboard and exit |
| `/` | Search forward |
| `n / N` | Next / previous match |
| `q` or `Esc` | Exit copy mode |

### Other Shortcuts

| Keybinding | Action |
|-----------|--------|
| `CTRL+Shift+C` | Copy to clipboard |
| `CTRL+Shift+V` | Paste from clipboard |
| Right-click | Paste (mouse shortcut) |
| `CTRL+click` | Open URL under cursor |
| `CTRL+=` / `CTRL+-` | Increase / decrease font size |
| `CTRL+0` | Reset font size |
| `LEADER + r` | Reload config without restart |
| `LEADER + e` | Open current selection (or viewport) in `$EDITOR` |
| `LEADER + f` | Search scrollback buffer |
| `LEADER + Space` | Quick select any text pattern |
| `LEADER + u` | Quick select URL and open in browser |
| `LEADER + ?` | Show all key assignments |

---

## Layouts

### 7-Pane Agent Grid

Press **LEADER + A** to expand the current tab into a 7-pane workspace — ideal for running multiple Claude Code agents in parallel:

```
+----------+----------+----------+----------+
|  Agent 1 |  Agent 2 |  Agent 3 |  Agent 4 |  <- top 60%
+----------+----------+----------+----------+
|  Agent 5 |  Agent 6 |       Agent 7       |  <- bottom 40%
+----------+----------+---------------------+
```

Each pane opens a PowerShell 7 session labelled Agent-1 through Agent-7.

### 2-Pane Side-by-Side

Press **LEADER + Shift+2** — splits the current pane 50/50 horizontally:

```
+---------------------+---------------------+
|       Editor        |      Terminal       |
+---------------------+---------------------+
```

### 3-Pane Code Layout

Press **LEADER + Shift+3** — editor on the left, tests and logs stacked on the right:

```
+---------------------+----------+
|                     |  Tests   |
|       Editor        +----------+
|                     |   Logs   |
+---------------------+----------+
```

> **Note:** Layout shortcuts add panes to the current tab. Close unwanted panes with `LEADER + x`.

---

## Built-in Multiplexer (Persistent Sessions)

WezTerm includes a built-in workspace system for organising your terminal sessions. Session persistence is handled entirely through JSON save files — no external server required.

**Auto-restore is enabled by default.** On startup WezTerm checks for `~/.wezterm_sessions/last.json` and restores your workspace layout automatically.

### Safely closing WezTerm (preserving your session)

| Action | What happens | Session preserved? |
|--------|-------------|-------------------|
| Close the WezTerm **window** (X button / Alt+F4) | WezTerm exits completely | Only if saved to disk |
| Open WezTerm again | Auto-restores from last save file | Yes (from last auto-save or manual save) |
| Say **Yes** to "kill all panes?" | Processes are killed, session is gone | No |
| `CTRL+D` in a shell | Exits that shell, closes that pane only | That pane lost |

**Rule of thumb:** Press `LEADER + Ctrl+S` before closing WezTerm to make sure your workspace layout is saved. Auto-save runs every 15 minutes, but a manual save guarantees nothing is lost.

### Session Persistence FAQ

**Q: What does LEADER+Ctrl+S save?**

It saves all workspace names, the active workspace, tab titles, and pane working directories to `%USERPROFILE%\.wezterm_sessions\last.json`. On the next startup (or when you press LEADER+Ctrl+R), WezTerm recreates those workspaces and opens panes in the correct directories.

**Q: Does it save running processes?**

No — terminal output and running processes are not saved. This matches the behaviour of tmux-resurrect. Your shell restarts fresh in the correct working directory.

**Q: How often does auto-save run?**

Every 15 minutes, matching tmux-continuum's default interval. The green **SAVED** badge in the status bar confirms each save. To change the interval, edit `AUTOSAVE_SECS` in `wezterm.lua`.

**Q: What is `prev.json` and how do I restore from it?**

Every time a save runs (manual or auto), the previous `last.json` is renamed to `prev.json` before being replaced. Press `LEADER + Ctrl+B` to restore from it. Named sessions are not affected by this rotation.

**Q: How do named sessions differ from the main save slot?**

Named sessions (`LEADER + Ctrl+N`) write to a separate `<name>.json` file and never overwrite `last.json` or `prev.json`. They persist indefinitely until you delete them with `LEADER + Ctrl+D`. Use them for project-specific layouts you want to keep permanently.

**Q: I closed WezTerm and my terminal output is gone. Can I get it back?**

No — terminal output lives in RAM. Once WezTerm exits, the scrollback is permanently gone. This is a fundamental property of all terminal emulators. Use `LEADER+Ctrl+S` before closing to save your workspace layout.

**Q: How much scrollback history is kept during a live session?**

20,000 lines (configurable via `config.scrollback_lines` in `wezterm.lua`). Use `LEADER+f` to search, `LEADER+e` to open a selection in your editor, or `CTRL+SHIFT+K` to clear the buffer.

---

## SSH Domains

Add remote servers to `wezterm.lua` and connect with `LEADER + D`:

```lua
config.ssh_domains = {
  { name = 'dev',  remote_address = '10.0.0.10',        username = 'ubuntu' },
  { name = 'prod', remote_address = 'prod.example.com',  username = 'deploy' },
}
```

WezTerm also auto-reads `~/.ssh/config` — no extra setup for hosts already defined there.

---

## Theme: Neon Dark

| Element | Value |
|---------|-------|
| Background | `#0d0d1a` (near-black indigo) |
| Foreground | `#ffffff` (pure white) |
| Cyan accent | `#00ffe1` (splits, active tab, workspace badge) |
| Magenta | `#ff00aa` (leader key indicator) |
| Green | `#00ff88` (session saved badge) |
| Yellow | `#ffe566` (pane count, git branch, zoom badge) |
| Cursor | Blinking cyan bar |
| Scrollbar | Cyan thumb (`#00ffe1`), auto-hides in alternate screen (vim/htop) |
| Backdrop | Solid (backdrop blur disabled for input latency) |
| Font | FiraCode Nerd Font Medium 14px |
| Ligatures | calt, clig, liga, ss01, ss03, ss05 |

---

## PowerShell Profile

The included profile (`Microsoft.PowerShell_profile.ps1`) auto-detects installed tools:

| Tool | Auto-detected? | Behaviour |
|------|---------------|-----------|
| **Starship** | Yes | Uses Starship for the prompt (git, language, docker indicators) |
| **zoxide** | Yes | Enables `z <dir>` for smart frecency-based navigation |
| Neither | — | Falls back to built-in neon prompt with git branch |

Install both via the installer, or separately:

```powershell
winget install Starship.Starship
winget install ajeetdsouza.zoxide
```

---

## Manual Installation

### Step 1 — Install WezTerm Nightly

Download the nightly installer (required — the stable release has a scrollbar rendering bug on Windows):

```powershell
Invoke-WebRequest -Uri "https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe" `
  -OutFile "$env:TEMP\WezTerm-nightly-setup.exe" -UseBasicParsing
Start-Process "$env:TEMP\WezTerm-nightly-setup.exe" -Wait
```

Or download the portable ZIP (no admin required):

```powershell
Invoke-WebRequest -Uri "https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-windows-nightly.zip" `
  -OutFile "$env:TEMP\WezTerm-nightly.zip" -UseBasicParsing
Expand-Archive "$env:TEMP\WezTerm-nightly.zip" -DestinationPath "$env:LOCALAPPDATA\WezTerm-nightly" -Force
```

> **Why nightly?** The last stable release (20240203) has a bug where the scrollbar never renders on Windows. The nightly builds (20260331+) fix this.

### Step 2 — Install PowerShell 7

```powershell
winget install --id Microsoft.PowerShell --source winget
```

### Step 3 — Install FiraCode Nerd Font

Download `FiraCode.zip` from the [nerd-fonts releases page](https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.3.0). Extract and install — no admin needed:

```powershell
$fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$regPath  = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
New-Item -Force -ItemType Directory $fontsDir | Out-Null
Get-ChildItem "$env:TEMP\FiraCode" -Filter *.ttf | ForEach-Object {
  $dst = Join-Path $fontsDir $_.Name
  Copy-Item $_.FullName $dst -Force
  Set-ItemProperty -Path $regPath -Name ($_.BaseName + " (TrueType)") -Value $dst
}
```

### Step 4 — Place the Config

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\wezterm"
Invoke-WebRequest "https://raw.githubusercontent.com/Muminur/tmux-alternative-windows/main/wezterm.lua" `
  -OutFile "$env:USERPROFILE\.config\wezterm\wezterm.lua"
Copy-Item "$env:USERPROFILE\.config\wezterm\wezterm.lua" "$env:USERPROFILE\.wezterm.lua"
```

---

## Install Locations

| Component | Default path |
|-----------|-------------|
| WezTerm binary | `C:\Program Files\WezTerm\` |
| PowerShell 7 | `C:\Program Files\PowerShell\7\` |
| FiraCode Nerd Font | `%LOCALAPPDATA%\Microsoft\Windows\Fonts\` |
| WezTerm config (primary) | `%USERPROFILE%\.config\wezterm\wezterm.lua` |
| WezTerm config (fallback) | `%USERPROFILE%\.wezterm.lua` |
| PowerShell profile | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| Session save directory | `%USERPROFILE%\.wezterm_sessions\` |

---

## Customising

The config lives at `~/.config/wezterm/wezterm.lua`. WezTerm hot-reloads on save — press `LEADER + r` to force reload. A toast notification confirms the reload.

```lua
config.font_size = 14.0                   -- font size
config.window_background_opacity = 1.0   -- 0.0 transparent, 1.0 solid (default: solid for best input latency)
config.leader = { key = 'a', mods = 'CTRL' }  -- change leader key

-- Window decorations: 'TITLE | RESIZE' shows OS title bar with minimize/maximize/close buttons
config.window_decorations = 'TITLE | RESIZE'

-- Change auto-save interval (seconds)
local AUTOSAVE_SECS = 10 * 60  -- 10 minutes instead of 15

-- Add SSH servers
config.ssh_domains = {
  { name = 'myserver', remote_address = '192.168.1.1', username = 'admin' },
}
```

---

## Troubleshooting

**winget error: "Failed when searching source: msstore" / certificate error 0x8a15005e**

The Microsoft Store source sometimes has SSL certificate issues on corporate or restricted networks. Add `--source winget` to skip the msstore source:

```powershell
winget install --id WezFurlong.WezTerm --source winget
winget install --id Microsoft.PowerShell --source winget
```

The installer script already includes `--source winget`.

---

**Font shows boxes or question marks**

```powershell
wezterm ls-fonts --list-system | Select-String fira
```

If nothing appears, reinstall the font. The config falls back to JetBrainsMono, then Cascadia Code, then Consolas.

---

**Config not loading after install**

WezTerm reads `~/.config/wezterm/wezterm.lua` first, then `~/.wezterm.lua`. The installer writes both. If neither loads, fully quit WezTerm from the system tray and reopen.

A toast notification saying "Config reloaded" confirms a successful hot-reload via `LEADER + r`.

---

**Window title bar buttons (minimize / maximize / close) not showing**

The config uses `config.window_decorations = 'TITLE | RESIZE'` which displays the OS title bar with all three window control buttons. If you previously had `'RESIZE'` in your config, the title bar was hidden. Re-download `wezterm.lua` or set:

```lua
config.window_decorations = 'TITLE | RESIZE'
```

---

**Session restore creates duplicate workspaces**

Press `LEADER + Ctrl+R` only when starting fresh. If you already have workspaces open, the restore will add more. Close unwanted workspaces with `LEADER + &`.

---

**LEADER+A does nothing / agent layout does not open**

Make sure you are running the latest `wezterm.lua` from this repo. Earlier versions had a Lua forward-reference bug that silently prevented the agent layout from spawning. Re-download with:

```powershell
install.ps1 -Update
```

---

**`wezterm-mux-server.exe` is running in Task Manager — is that normal?**

Yes. `wezterm-mux-server.exe` is WezTerm's internal mux process. It exits when you close WezTerm. Use `LEADER + Ctrl+S` to save your session before closing if you want to restore it later.

---

**Blank pane windows appear on startup / duplicate WezTerm windows**

If WezTerm is launched while another instance is already running, each process starts its own mux server and fires the startup event independently, producing duplicate blank panes. The config guards against this with a 30-second timestamp lock file (`~/.wezterm_startup.lock`) — a second launch within that window skips the workspace spawn entirely.

To clean up existing duplicates: close the extra blank windows manually (they have no content) or from PowerShell:

```powershell
# Find and close extra blank WezTerm pane processes (check they're idle first)
Get-Process pwsh | Where-Object { $_.MainWindowTitle -eq '' } | Stop-Process -Confirm
```

To prevent it: **never launch WezTerm when it is already open**. Use `LEADER+c` for a new tab or `LEADER+W` for a new workspace instead.

---

**WSL errors in panes on startup**

The config defaults to PowerShell 7. If WSL is not installed, some launcher entries may error. Install WSL with:

```powershell
wsl --install
```

---

**Git branch not showing in status bar**

The status bar queries `git` in the background for the active pane's directory. If git is not in PATH or the directory is not a git repo, the branch segment is hidden. Results are cached for 30 seconds per directory to avoid performance impact.

---

## Repository Structure

```
tmux-alternative-windows/
├── install.ps1                       # One-line installer script
├── wezterm.lua                       # Full WezTerm Lua config (all features)
├── Microsoft.PowerShell_profile.ps1  # Neon PS7 profile (Starship/zoxide auto-detect)
├── screenshots/
│   ├── wezterm-2pane-neon.png        # 2-pane neon dark layout
│   └── wezterm-status-bar.png        # Status bar detail
└── README.md
```

---

## Contributing

Open an issue or pull request. Suggestions welcome for:

- Additional colour themes
- More SSH domain examples
- WSL integration improvements
- Extra keybinding configurations
- Additional layout presets

---

## Related Links

- [WezTerm official documentation](https://wezfurlong.org/wezterm/)
- [WezTerm Lua API reference](https://wezfurlong.org/wezterm/config/lua/general.html)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) — the tmux plugin this feature mirrors
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) — the tmux plugin this auto-save mirrors
- [FiraCode Nerd Font releases](https://github.com/ryanoasis/nerd-fonts/releases)
- [PowerShell 7 on GitHub](https://github.com/PowerShell/PowerShell)
- [Starship prompt](https://starship.rs/)
- [zoxide](https://github.com/ajeetdsouza/zoxide)

---

## License

MIT — use freely, fork, and modify as you like.

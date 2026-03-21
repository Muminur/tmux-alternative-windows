# WezTerm: The Best tmux Alternative for Windows

> **Replace tmux on Windows** with a GPU-accelerated, natively multiplexing terminal.
> Zero dependencies, one config file, works out of the box on Windows 10/11.

[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?logo=windows&logoColor=white)](https://wezfurlong.org/wezterm/)
[![WezTerm](https://img.shields.io/badge/WezTerm-Latest-00ffe1)](https://wezfurlong.org/wezterm/)
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

> **Requirement:** Windows 10/11 with `winget` (App Installer from the Microsoft Store)

---

## Screenshots

### 2-Pane Workspace — Neon Dark Theme

![WezTerm neon dark 2-pane layout on Windows with cyan divider and status bar](screenshots/wezterm-2pane-neon.png)

*Two PowerShell 7 panes side-by-side. Neon cyan split line. Status bar shows workspace name, active process, and clock. Opens automatically on WezTerm launch.*

### Status Bar Detail

![WezTerm status bar showing main workspace powershell.exe process name and clock](screenshots/wezterm-status-bar.png)

*Right-side status bar: workspace indicator (cyan), active process name (purple), battery level, and live clock. Active tab highlighted in neon cyan.*

---

## Why WezTerm Instead of tmux on Windows?

tmux requires WSL or Cygwin on Windows — it is a Linux tool bolted onto Windows. WezTerm is a **native Windows application** built from scratch, with a full terminal multiplexer included.

| Feature | tmux via WSL | WezTerm native |
|---------|:---:|:---:|
| Pane splitting | Yes | Yes |
| Persistent sessions | Yes | Yes |
| Session save & restore | tmux-resurrect plugin | **Built-in** |
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

---

## Session Save & Restore (tmux-resurrect / tmux-continuum)

This config implements the same session persistence policy as the popular tmux plugins:

| tmux plugin | WezTerm equivalent |
|------------|-------------------|
| `tmux-resurrect` — manual save/restore | `LEADER + Ctrl+S` / `LEADER + Ctrl+R` |
| `tmux-continuum` — auto-save every 15 min | Built-in auto-save timer |
| `tmux-continuum` — auto-restore on start | Auto-restores on mux server startup |

**What is saved:**
- All workspace names (equivalent to tmux sessions)
- All tab titles (equivalent to tmux windows)
- All pane working directories
- Pane layout (split directions reconstructed from saved positions)

**Save file:** `%USERPROFILE%\.wezterm_sessions\last.json`

### How it works

```
On startup:
  1. Check if mux server already has workspaces → if yes, reattach (no restart)
  2. Check if ~/.wezterm_sessions/last.json exists → if yes, restore it
  3. Otherwise → create default 'main' workspace with 2-pane layout

Every 15 minutes:
  Auto-save all workspaces to last.json

LEADER + Ctrl+S:
  Save immediately + show "SAVED" in status bar for 30 seconds

LEADER + Ctrl+R:
  Restore from last.json into current session (adds workspaces)
```

### Status bar indicator

After a save (manual or auto), the status bar shows a green **SAVED** badge for 30 seconds so you can confirm the save completed.

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
| `LEADER + A` | **Spawn 7-pane agent layout** |

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

### Session Save & Restore (tmux-resurrect style)

| Keybinding | Action |
|-----------|--------|
| `LEADER + Ctrl+S` | **Save session** — writes all workspaces/tabs/panes to disk |
| `LEADER + Ctrl+R` | **Restore session** — recreates workspaces from last save |

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
| `LEADER + f` | Search scrollback buffer |
| `LEADER + Space` | Quick select any text pattern |
| `LEADER + u` | Quick select URL and open in browser |
| `LEADER + ?` | Show all key assignments |

---

## 7-Pane Agent Layout

Press **LEADER + A** to expand the current tab into a 7-pane workspace — ideal for running multiple Claude Code agents in parallel:

```
+----------+----------+----------+----------+
|  Agent 1 |  Agent 2 |  Agent 3 |  Agent 4 |  <- top 60%
+----------+----------+----------+----------+
|  Agent 5 |  Agent 6 |       Agent 7       |  <- bottom 40%
+----------+----------+---------------------+
```

Each pane opens a PowerShell 7 session labelled Agent-1 through Agent-7. Other tabs and workspaces are untouched.

---

## Built-in Multiplexer (Persistent Sessions)

WezTerm includes a built-in session server — like `tmux new-session` but with nothing extra to install.

**Auto-attach is enabled by default.** WezTerm starts a persistent mux server on launch and reconnects to your existing workspaces automatically.

Connect manually from a new terminal window:

```powershell
wezterm connect mux
```

### Safely closing WezTerm (preserving your session)

| Action | What happens | Session preserved? |
|--------|-------------|-------------------|
| Close the WezTerm **window** (X button / Alt+F4) | GUI closes, mux server keeps running | Yes |
| Open WezTerm again | Auto-reconnects to running mux server, all panes intact | Yes |
| Say **Yes** to "kill all panes?" | Processes are killed, session is gone | No |
| `CTRL+D` in a shell | Exits that shell, closes that pane only | That pane lost |

**Rule of thumb:** To preserve your session without a save file, always close the WezTerm **window** — never say "yes" to killing panes. The mux server (`wezterm-mux-server.exe`) keeps running in the background.

With session save/restore (`LEADER + Ctrl+S`), you can safely kill the mux server and fully restore your workspace layout on next startup.

### Session Persistence FAQ

**Q: What does LEADER+Ctrl+S save?**

It saves all workspace names, tab titles, and pane working directories to `%USERPROFILE%\.wezterm_sessions\last.json`. On the next startup (or when you press LEADER+Ctrl+R), WezTerm recreates those workspaces and opens panes in the correct directories.

**Q: Does it save running processes?**

No — terminal output and running processes are not saved. This matches the behaviour of tmux-resurrect (which also cannot restore arbitrary process state). Your shell restarts fresh in the correct working directory.

**Q: How often does auto-save run?**

Every 15 minutes, matching tmux-continuum's default interval. The green **SAVED** badge in the status bar confirms each save. To change the interval, edit `AUTOSAVE_SECS` in `wezterm.lua`.

**Q: I closed WezTerm and my terminal output is gone. Can I get it back?**

No — terminal output lives in RAM. Once the mux server exits, the scrollback is permanently gone. This is a fundamental property of all terminal multiplexers (tmux, screen, WezTerm). Use `LEADER+Ctrl+S` before closing to save your workspace layout.

**Q: My typed commands are gone too — can I get those back?**

Yes — PowerShell command history is preserved automatically by PSReadLine, regardless of WezTerm restarts. Press the **Up arrow** after reopening to access your previous commands.

History is saved to:
```
%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
```

**Q: How much scrollback history is kept during a live session?**

20,000 lines (configurable via `config.scrollback_lines` in `wezterm.lua`). Use `LEADER+f` to search the scrollback, or `CTRL+SHIFT+K` to clear it.

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
| Yellow | `#ffe566` |
| Cursor | Blinking cyan bar |
| Backdrop | Windows Acrylic blur |
| Font | FiraCode Nerd Font Medium 14px |
| Ligatures | calt, clig, liga, ss01, ss03, ss05 |

---

## Manual Installation

### Step 1 — Install WezTerm

```powershell
winget install --id WezFurlong.WezTerm --source winget
```

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

The config lives at `~/.config/wezterm/wezterm.lua`. WezTerm hot-reloads on save — press `LEADER + r` to force reload.

```lua
config.font_size = 14.0                   -- font size
config.window_background_opacity = 0.97  -- 0.0 transparent, 1.0 solid
config.leader = { key = 'a', mods = 'CTRL' }  -- change leader key

-- Window decorations: 'TITLE | RESIZE' shows OS title bar with minimize/maximize/close buttons
-- Change to 'RESIZE' to hide the title bar (buttons disappear), or 'NONE' for borderless
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

---

**Window title bar buttons (minimize / maximize / close) not showing**

The config uses `config.window_decorations = 'TITLE | RESIZE'` which displays the OS title bar with all three window control buttons. If you previously had `'RESIZE'` in your config, the title bar was hidden. Re-download `wezterm.lua` or set:

```lua
config.window_decorations = 'TITLE | RESIZE'
```

---

**Error: "local is a built-in domain"**

Old config has `name = 'local'` in `unix_domains`. The current config uses `name = 'mux'`. Re-download `wezterm.lua` to fix.

---

**Session restore creates duplicate workspaces**

Press `LEADER + Ctrl+R` only when starting fresh. If you already have workspaces open, the restore will add more (the existing ones are unaffected). Close unwanted workspaces with `LEADER + &`.

---

**WSL errors in panes on startup**

The config defaults to PowerShell 7. If WSL is not installed, some launcher entries may error. Install WSL with:

```powershell
wsl --install
```

---

## Repository Structure

```
tmux-alternative-windows/
├── install.ps1                       # One-line installer script
├── wezterm.lua                       # Full WezTerm Lua config (session save/restore included)
├── Microsoft.PowerShell_profile.ps1  # Neon PS7 profile
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

---

## Related Links

- [WezTerm official documentation](https://wezfurlong.org/wezterm/)
- [WezTerm Lua API reference](https://wezfurlong.org/wezterm/config/lua/general.html)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) — the tmux plugin this feature mirrors
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) — the tmux plugin this auto-save mirrors
- [FiraCode Nerd Font releases](https://github.com/ryanoasis/nerd-fonts/releases)
- [PowerShell 7 on GitHub](https://github.com/PowerShell/PowerShell)

---

## License

MIT — use freely, fork, and modify as you like.

-- ============================================================
--  WezTerm — Full-Featured Config
--  Theme     : Neon Dark (custom)
--  Font      : FiraCode Nerd Font (ligatures on)
--  Shell     : WSL bash (default) + PowerShell
--  Agents    : 7-pane Claude Code workspace on startup
--  Work tab  : left=WSL  right=PowerShell
--  Leader    : CTRL+B  (tmux default)
--  Mux       : built-in unix domain (wezterm connect local)
-- ============================================================

local wezterm = require 'wezterm'
local act     = wezterm.action
local mux     = wezterm.mux

local config  = wezterm.config_builder()

-- ============================================================
-- NEON DARK COLOR SCHEME
-- ============================================================
local neon = {
  bg          = '#0d0d1a',
  bg_alt      = '#11111f',
  bg_panel    = '#14142a',
  bg_sel      = '#1e1e3f',
  fg          = '#ffffff',   -- pure white, maximum visibility
  fg_dim      = '#aabbdd',
  cyan        = '#00ffe1',
  magenta     = '#ff00aa',
  green       = '#00ff88',
  yellow      = '#ffe566',
  blue        = '#4fc3f7',
  red         = '#ff4466',
  orange      = '#ff9f00',
  purple      = '#b48eff',
  white       = '#e0e0ff',
  black       = '#0a0a14',
}

config.color_schemes = {
  ['NeonDark'] = {
    background    = neon.bg,
    foreground    = neon.fg,
    cursor_bg     = neon.cyan,
    cursor_border = neon.cyan,
    cursor_fg     = neon.black,
    selection_bg  = neon.bg_sel,
    selection_fg  = neon.white,
    scrollbar_thumb  = neon.bg_panel,
    split            = neon.cyan,
    compose_cursor   = neon.orange,
    visual_bell      = neon.magenta,

    ansi = {
      neon.black, neon.red,    neon.green,  neon.yellow,
      neon.blue,  neon.magenta,neon.cyan,   '#ffffff',
    },
    brights = {
      '#2a2a3e', '#ff6680', '#44ffaa', '#ffe066',
      '#80d8ff', '#ff44cc', '#44fff0', '#ffffff',
    },

    tab_bar = {
      background = neon.bg,
      active_tab = {
        bg_color  = neon.cyan,  fg_color = neon.black,
        intensity = 'Bold',
      },
      inactive_tab       = { bg_color = neon.bg_panel, fg_color = neon.fg_dim  },
      inactive_tab_hover = { bg_color = neon.bg_sel,   fg_color = neon.fg      },
      new_tab            = { bg_color = neon.bg,        fg_color = neon.cyan   },
      new_tab_hover      = { bg_color = neon.bg_panel,  fg_color = neon.magenta},
    },
  },
}
config.color_scheme = 'NeonDark'

-- ============================================================
-- FONT  — FiraCode Nerd Font with ligatures
-- ============================================================
config.font = wezterm.font_with_fallback {
  {
    family            = 'FiraCode Nerd Font',
    weight            = 'Medium',
    harfbuzz_features = { 'calt=1','clig=1','liga=1','ss01=1','ss03=1','ss05=1' },
  },
  { family = 'FiraCode',               weight = 'Regular' },
  { family = 'JetBrainsMono Nerd Font' },
  { family = 'Cascadia Code NF'        },
  { family = 'Cascadia Code',          harfbuzz_features = { 'calt=1','liga=1' } },
  { family = 'Cascadia Mono'           },
  { family = 'Consolas'                },
  'Noto Color Emoji',
}
config.font_size   = 14.0
config.line_height = 1.15
config.cell_width  = 1.0

-- ============================================================
-- WINDOW — transparent neon glass
-- ============================================================
config.initial_cols = 230
config.initial_rows = 56

config.window_background_opacity = 0.97
config.text_background_opacity   = 1.0
config.win32_system_backdrop     = 'Acrylic'

config.window_decorations = 'RESIZE'
config.window_padding = { left = 6, right = 6, top = 4, bottom = 0 }

config.window_frame = {
  font      = wezterm.font { family = 'FiraCode Nerd Font', weight = 'Bold' },
  font_size = 11.0,
  active_titlebar_bg            = neon.bg,
  inactive_titlebar_bg          = neon.black,
  active_titlebar_fg            = neon.cyan,
  inactive_titlebar_fg          = neon.fg_dim,
  active_titlebar_border_bottom = neon.cyan,
  inactive_titlebar_border_bottom = neon.bg_panel,
  button_fg       = neon.cyan,
  button_bg       = neon.bg,
  button_hover_fg = neon.black,
  button_hover_bg = neon.cyan,
}

-- ============================================================
-- TAB BAR
-- ============================================================
config.enable_tab_bar               = true
config.use_fancy_tab_bar            = true
config.tab_bar_at_bottom            = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width                = 36
config.show_tab_index_in_tab_bar    = false

-- ============================================================
-- CURSOR
-- ============================================================
config.default_cursor_style  = 'BlinkingBar'
config.cursor_blink_rate     = 400
config.cursor_blink_ease_in  = 'EaseIn'
config.cursor_blink_ease_out = 'EaseOut'

-- ============================================================
-- SCROLLBACK
-- ============================================================
config.enable_scroll_bar                    = true
config.scrollback_lines                     = 20000
config.alternate_buffer_wheel_scroll_speed  = 3

-- ============================================================
-- SHELL — PowerShell (PS7 if available, PS5 fallback)
-- ============================================================
local function find_pwsh()
  -- Check PS7 default install paths first
  local paths = {
    'C:/Program Files/PowerShell/7/pwsh.exe',
    'C:/Program Files/PowerShell/7-preview/pwsh.exe',
  }
  for _, p in ipairs(paths) do
    local f = io.open(p, 'r')
    if f then f:close(); return p end
  end
  -- Fall back to PATH lookup
  local f = io.popen('where pwsh.exe 2>nul')
  if f then
    local out = f:read('*l')
    f:close()
    if out and #out > 0 then return out:gsub('%s+$', '') end
  end
  return nil
end

local pwsh = find_pwsh()
if pwsh then
  config.default_prog = { pwsh, '-NoLogo' }
else
  config.default_prog = { 'powershell.exe', '-NoLogo' }
end

-- ============================================================
-- BUILT-IN MULTIPLEXER  (like tmux — persists sessions)
--   Attach:  wezterm connect local
--   Or make it the default startup (uncomment below):
-- ============================================================
config.unix_domains = {
  { name = 'mux' },
}
config.default_gui_startup_args = { 'connect', 'mux' }

-- ============================================================
-- SSH DOMAINS  — add your servers here
-- ============================================================
config.ssh_domains = {
  -- Example entries — fill in your own hosts:
  -- { name = 'dev-server',  remote_address = '10.0.0.10',        username = 'ubuntu' },
  -- { name = 'prod',        remote_address = 'prod.example.com', username = 'deploy' },
  -- WezTerm also auto-discovers hosts from ~/.ssh/config
}

-- ============================================================
-- BELL
-- ============================================================
config.audible_bell = 'Disabled'
config.visual_bell  = {
  fade_in_function     = 'EaseIn',  fade_in_duration_ms  = 80,
  fade_out_function    = 'EaseOut', fade_out_duration_ms = 80,
}

-- ============================================================
-- HYPERLINKS / URL detection
-- ============================================================
config.hyperlink_rules = wezterm.default_hyperlink_rules()

table.insert(config.hyperlink_rules, {
  regex  = [=[\b(https?|ftp|file)://\S+[^\s,\.)\]'"]*]=],
  format = '$0',
})
table.insert(config.hyperlink_rules, {
  regex  = [=[["]?([\w\d][-\w\d]+)(/)([-\w\d\.]+)["]?]=],
  format = 'https://github.com/$1/$3',
})

-- ============================================================
-- QUICK SELECT PATTERNS  (LEADER + Space)
-- ============================================================
config.quick_select_patterns = {
  'https?://[\\w./?=&%\\-#@!~:+]+',
  '[/~][\\w./\\-]+',
  'C:\\\\[\\w\\\\./\\-]+',
  '[0-9a-f]{7,40}',
  '\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(?::\\d+)?',
  '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
  '\\bAgent-[0-9]+\\b',
}

-- ============================================================
-- MOUSE BINDINGS
-- ============================================================
config.mouse_bindings = {
  -- Right-click → paste
  { event = { Down = { streak=1, button='Right'  } }, mods='NONE',
    action = act.PasteFrom 'Clipboard' },
  -- Ctrl+click → open link
  { event = { Up   = { streak=1, button='Left'   } }, mods='CTRL',
    action = act.OpenLinkAtMouseCursor },
  -- Middle-click → paste primary
  { event = { Down = { streak=1, button='Middle' } }, mods='NONE',
    action = act.PasteFrom 'PrimarySelection' },
  -- Triple-click → select line
  { event = { Down = { streak=3, button='Left'   } }, mods='NONE',
    action = act.SelectTextAtMouseCursor 'Line' },
  -- Shift+scroll → scroll faster
  { event = { Down = { streak=1, button={ WheelUp=1   } } }, mods='SHIFT',
    action = act.ScrollByPage(-0.5) },
  { event = { Down = { streak=1, button={ WheelDown=1 } } }, mods='SHIFT',
    action = act.ScrollByPage(0.5) },
}

-- ============================================================
-- LEADER KEY — CTRL+B  (tmux default, 2-second window)
-- ============================================================
config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 2000 }

-- ============================================================
-- KEY BINDINGS  (all tmux-equivalent)
-- ============================================================
config.keys = {

  -- ── PANE SPLITTING ─────────────────────────────────────────
  -- LEADER+|  or  LEADER+%  → split right (vertical divider)
  -- LEADER+-  or  LEADER+"  → split down  (horizontal divider)
  { key='|', mods='LEADER', action=act.SplitHorizontal { domain='CurrentPaneDomain' } },
  { key='%', mods='LEADER', action=act.SplitHorizontal { domain='CurrentPaneDomain' } },
  { key='-', mods='LEADER', action=act.SplitVertical   { domain='CurrentPaneDomain' } },
  { key='"', mods='LEADER', action=act.SplitVertical   { domain='CurrentPaneDomain' } },

  -- ── PANE NAVIGATION ────────────────────────────────────────
  { key='h',          mods='LEADER', action=act.ActivatePaneDirection 'Left'  },
  { key='j',          mods='LEADER', action=act.ActivatePaneDirection 'Down'  },
  { key='k',          mods='LEADER', action=act.ActivatePaneDirection 'Up'    },
  { key='l',          mods='LEADER', action=act.ActivatePaneDirection 'Right' },
  { key='LeftArrow',  mods='LEADER', action=act.ActivatePaneDirection 'Left'  },
  { key='DownArrow',  mods='LEADER', action=act.ActivatePaneDirection 'Down'  },
  { key='UpArrow',    mods='LEADER', action=act.ActivatePaneDirection 'Up'    },
  { key='RightArrow', mods='LEADER', action=act.ActivatePaneDirection 'Right' },

  -- ── PANE RESIZE ────────────────────────────────────────────
  { key='H', mods='LEADER', action=act.AdjustPaneSize { 'Left',  5 } },
  { key='J', mods='LEADER', action=act.AdjustPaneSize { 'Down',  5 } },
  { key='K', mods='LEADER', action=act.AdjustPaneSize { 'Up',    5 } },
  { key='L', mods='LEADER', action=act.AdjustPaneSize { 'Right', 5 } },

  -- ── PANE MANAGEMENT ────────────────────────────────────────
  { key='z', mods='LEADER', action=act.TogglePaneZoomState },
  { key='x', mods='LEADER', action=act.CloseCurrentPane { confirm=true } },
  { key='{', mods='LEADER', action=act.RotatePanes 'CounterClockwise' },
  { key='}', mods='LEADER', action=act.RotatePanes 'Clockwise' },
  { key='o', mods='LEADER', action=act.PaneSelect },
  { key='q', mods='LEADER', action=act.PaneSelect { mode='SwapWithActiveKeepFocus' } },

  -- ── TABS (like tmux windows) ────────────────────────────────
  { key='c', mods='LEADER', action=act.SpawnTab 'CurrentPaneDomain' },
  { key='n', mods='LEADER', action=act.ActivateTabRelative(1)  },
  { key='p', mods='LEADER', action=act.ActivateTabRelative(-1) },
  { key='&', mods='LEADER', action=act.CloseCurrentTab { confirm=true } },
  { key=',', mods='LEADER', action=act.PromptInputLine {
      description = 'Rename tab:',
      action = wezterm.action_callback(function(window, _, line)
        if line then window:active_tab():set_title(line) end
      end),
  }},
  -- Quick switch 1–9
  { key='1', mods='LEADER', action=act.ActivateTab(0) },
  { key='2', mods='LEADER', action=act.ActivateTab(1) },
  { key='3', mods='LEADER', action=act.ActivateTab(2) },
  { key='4', mods='LEADER', action=act.ActivateTab(3) },
  { key='5', mods='LEADER', action=act.ActivateTab(4) },
  { key='6', mods='LEADER', action=act.ActivateTab(5) },
  { key='7', mods='LEADER', action=act.ActivateTab(6) },
  { key='8', mods='LEADER', action=act.ActivateTab(7) },
  { key='9', mods='LEADER', action=act.ActivateTab(-1) },

  -- ── WORKSPACES (like tmux sessions) ────────────────────────
  { key='w', mods='LEADER', action=act.ShowLauncherArgs { flags='FUZZY|WORKSPACES' } },
  { key='s', mods='LEADER', action=act.ShowLauncherArgs { flags='FUZZY|WORKSPACES|TABS|LAUNCH_MENU_ITEMS' } },
  { key='$', mods='LEADER', action=act.PromptInputLine {
      description = 'Rename workspace:',
      action = wezterm.action_callback(function(_, _, line)
        if line then mux.rename_workspace(mux.get_active_workspace(), line) end
      end),
  }},
  { key='W', mods='LEADER', action=act.PromptInputLine {
      description = 'New workspace name:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and #line > 0 then
          window:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
  }},

  -- ── COPY / SEARCH ───────────────────────────────────────────
  { key='[',     mods='LEADER', action=act.ActivateCopyMode },
  { key='f',     mods='LEADER', action=act.Search { CaseSensitiveString='' } },
  { key='Space', mods='LEADER', action=act.QuickSelect },
  -- LEADER+u  — quick-select URL and open in browser
  { key='u', mods='LEADER', action=act.QuickSelectArgs {
      label    = 'open url',
      patterns = { 'https?://\\S+' },
      action   = wezterm.action_callback(function(window, pane)
        local url = window:get_selection_text_for_pane(pane)
        if url and #url > 0 then wezterm.open_with(url) end
      end),
  }},

  -- ── CLIPBOARD ───────────────────────────────────────────────
  { key='c', mods='CTRL|SHIFT', action=act.CopyTo 'Clipboard' },
  { key='v', mods='CTRL|SHIFT', action=act.PasteFrom 'Clipboard' },

  -- ── FONT SIZE ────────────────────────────────────────────────
  { key='=', mods='CTRL', action=act.IncreaseFontSize },
  { key='-', mods='CTRL', action=act.DecreaseFontSize },
  { key='0', mods='CTRL', action=act.ResetFontSize    },

  -- ── SSH / DOMAINS ────────────────────────────────────────────
  -- LEADER+D  → domain/connection launcher
  { key='D', mods='LEADER', action=act.ShowLauncherArgs { flags='FUZZY|DOMAINS' } },

  -- ── MISC ─────────────────────────────────────────────────────
  { key='r', mods='LEADER',     action=act.ReloadConfiguration },
  { key='?', mods='LEADER',     action=act.ShowLauncherArgs { flags='FUZZY|KEY_ASSIGNMENTS' } },
  { key='N', mods='CTRL|SHIFT', action=act.SpawnWindow },
  { key='T', mods='CTRL|SHIFT', action=act.ShowTabNavigator },
  -- Clear scrollback (tmux-style Ctrl+B + K)
  { key='k', mods='CTRL|SHIFT', action=act.Multiple {
      act.ClearScrollback 'ScrollbackAndViewport',
      act.SendKey { key='l', mods='CTRL' },
  }},

  -- ── AGENT LAYOUT respawn ─────────────────────────────────────
  -- LEADER+A  → re-create 7-pane Claude Code layout in current tab
  { key='A', mods='LEADER', action=wezterm.action_callback(function(_, pane)
      spawn_agent_layout(pane)
  end)},
}

-- ============================================================
-- COPY MODE key table (full vim motions)
-- ============================================================
config.key_tables = {
  copy_mode = {
    { key='q',        mods='NONE', action=act.CopyMode 'Close' },
    { key='Escape',   mods='NONE', action=act.CopyMode 'Close' },
    { key='h',        mods='NONE', action=act.CopyMode 'MoveLeft'              },
    { key='j',        mods='NONE', action=act.CopyMode 'MoveDown'              },
    { key='k',        mods='NONE', action=act.CopyMode 'MoveUp'                },
    { key='l',        mods='NONE', action=act.CopyMode 'MoveRight'             },
    { key='w',        mods='NONE', action=act.CopyMode 'MoveForwardWord'       },
    { key='b',        mods='NONE', action=act.CopyMode 'MoveBackwardWord'      },
    { key='e',        mods='NONE', action=act.CopyMode 'MoveForwardWordEnd'    },
    { key='0',        mods='NONE', action=act.CopyMode 'MoveToStartOfLine'     },
    { key='$',        mods='NONE', action=act.CopyMode 'MoveToEndOfLineContent'},
    { key='g',        mods='NONE', action=act.CopyMode 'MoveToScrollbackTop'   },
    { key='G',        mods='NONE', action=act.CopyMode 'MoveToScrollbackBottom'},
    { key='v',        mods='NONE', action=act.CopyMode { SetSelectionMode='Cell'  } },
    { key='V',        mods='NONE', action=act.CopyMode { SetSelectionMode='Line'  } },
    { key='v',        mods='CTRL', action=act.CopyMode { SetSelectionMode='Block' } },
    { key='y',        mods='NONE', action=act.Multiple {
        act.CopyTo 'ClipboardAndPrimarySelection', act.CopyMode 'Close',
    }},
    { key='PageUp',   mods='NONE', action=act.CopyMode 'PageUp'   },
    { key='PageDown', mods='NONE', action=act.CopyMode 'PageDown' },
    { key='u',        mods='CTRL', action=act.CopyMode 'PageUp'   },
    { key='d',        mods='CTRL', action=act.CopyMode 'PageDown' },
    { key='/',        mods='NONE', action=act.Search { CaseSensitiveString='' } },
    { key='n',        mods='NONE', action=act.CopyMode 'NextMatch'  },
    { key='N',        mods='NONE', action=act.CopyMode 'PriorMatch' },
  },
  search_mode = {
    { key='Escape', mods='NONE', action=act.CopyMode 'Close'          },
    { key='Enter',  mods='NONE', action=act.ActivateCopyMode          },
    { key='r',      mods='CTRL', action=act.CopyMode 'CycleMatchType' },
    { key='u',      mods='CTRL', action=act.CopyMode 'ClearPattern'   },
    { key='n',      mods='CTRL', action=act.CopyMode 'NextMatch'      },
    { key='p',      mods='CTRL', action=act.CopyMode 'PriorMatch'     },
  },
}

-- ============================================================
-- STATUS BAR  (leader indicator | workspace | process | battery | clock)
-- ============================================================
wezterm.on('update-status', function(window, pane)
  local parts = {}

  -- Leader active
  if window:leader_is_active() then
    parts[#parts+1] = wezterm.format {
      { Background = { Color = neon.magenta } },
      { Foreground = { Color = neon.black   } },
      { Attribute  = { Intensity = 'Bold'   } },
      { Text = '  WAIT  ' },
    }
  end

  -- Workspace
  local ws = mux.get_active_workspace()
  parts[#parts+1] = wezterm.format {
    { Background = { Color = neon.cyan  } },
    { Foreground = { Color = neon.black } },
    { Attribute  = { Intensity = 'Bold' } },
    { Text = '  ' .. ws .. ' ' },
  }

  -- Active process
  local proc = pane:get_foreground_process_name() or ''
  if proc ~= '' then
    proc = proc:match('([^/\\]+)$') or proc
    parts[#parts+1] = wezterm.format {
      { Background = { Color = neon.bg_panel } },
      { Foreground = { Color = neon.purple   } },
      { Text = '  ' .. proc .. ' ' },
    }
  end

  -- Battery (laptop-friendly)
  local ok, bats = pcall(wezterm.battery_info)
  if ok and bats and #bats > 0 then
    for _, b in ipairs(bats) do
      local pct  = math.floor(b.state_of_charge * 100)
      local col  = pct > 30 and neon.green or neon.red
      local icon = b.state == 'Charging' and ' ' or ' '
      parts[#parts+1] = wezterm.format {
        { Background = { Color = neon.bg_alt } },
        { Foreground = { Color = col         } },
        { Text = ' ' .. icon .. pct .. '% ' },
      }
    end
  end

  -- Clock
  parts[#parts+1] = wezterm.format {
    { Background = { Color = neon.bg_alt } },
    { Foreground = { Color = neon.fg_dim } },
    { Text = '  ' .. wezterm.strftime '%a %d %b  %H:%M ' },
  }

  window:set_right_status(table.concat(parts))
end)

-- ============================================================
-- TAB TITLE
-- ============================================================
wezterm.on('format-tab-title', function(tab, _, _, _, _, max_width)
  local p     = tab.active_pane
  local title = (p.title and #p.title > 0) and p.title or 'bash'
  local idx   = tab.tab_index + 1
  local max_t = max_width - 6
  if #title > max_t then title = title:sub(1, max_t-1) .. '…' end
  local label = ' ' .. idx .. ' ' .. title .. ' '
  if tab.is_active then
    return {
      { Background = { Color = neon.cyan  } },
      { Foreground = { Color = neon.black } },
      { Attribute  = { Intensity = 'Bold' } },
      { Text = label },
    }
  else
    return {
      { Background = { Color = neon.bg_panel } },
      { Foreground = { Color = neon.fg_dim   } },
      { Text = label },
    }
  end
end)

-- ============================================================
-- 7-PANE AGENT LAYOUT
--
--   ┌──────┬──────┬──────┬──────┐
--   │  1   │  2   │  3   │  4   │  60%
--   ├──────┼──────┼──────┴──────┤
--   │  5   │  6   │      7      │  40%
--   └──────┴──────┴─────────────┘
-- ============================================================
function spawn_agent_layout(root_pane)
  local agents = {
    { id=1, col='\\[\\e[96m\\]' },  -- bright cyan
    { id=2, col='\\[\\e[95m\\]' },  -- bright magenta
    { id=3, col='\\[\\e[92m\\]' },  -- bright green
    { id=4, col='\\[\\e[93m\\]' },  -- bright yellow
    { id=5, col='\\[\\e[94m\\]' },  -- bright blue
    { id=6, col='\\[\\e[91m\\]' },  -- bright red
    { id=7, col='\\[\\e[97m\\]' },  -- bright white
  }

  -- Split into top 60% (root keeps top) and bottom 40%
  local bot1 = root_pane:split { direction='Bottom', size=0.4 }

  -- Top row → 4 equal panes
  local p2 = root_pane:split { direction='Right', size=0.75 }
  local p3 = p2:split        { direction='Right', size=0.67 }
  local p4 = p3:split        { direction='Right', size=0.50 }

  -- Bottom row → 3 panes (left two equal, right one double-width)
  local bot2 = bot1:split { direction='Right', size=0.67 }
  local bot3 = bot2:split { direction='Right', size=0.50 }

  local panes = { root_pane, p2, p3, p4, bot1, bot2, bot3 }

  for i, p in ipairs(panes) do
    -- Set PowerShell window title to agent label and clear screen
    p:send_text('$Host.UI.RawUI.WindowTitle = "Agent-' .. i .. '"; Clear-Host\r')
  end
end

-- ============================================================
-- GUI STARTUP
--   Opens 2 panes side by side (left + right).
--   Press LEADER+A any time to expand into the full 7-pane
--   Claude Code agent layout.
-- ============================================================
wezterm.on('gui-startup', function()
  local shell = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }

  local wins = mux.all_windows()

  if #wins > 0 then
    -- connect-mux created a window already; use it instead of spawning a 2nd one
    local w    = wins[1]
    local tabs = w:tabs()
    if #tabs > 0 then
      local t     = tabs[1]
      local panes = t:panes()
      if #panes == 1 then
        -- Fresh mux session: split the single pane into two
        panes[1]:split { direction = 'Right', size = 0.5, args = shell }
        t:set_title('Work')
      end
      -- >1 pane means we reconnected to an existing session — leave it alone
    end
    return
  end

  -- No windows at all: create the 2-pane layout from scratch
  local tab, left, win = mux.spawn_window { workspace = 'main', args = shell }
  tab:set_title('Work')
  pcall(function() win:gui_window():maximize() end)
  left:split { direction = 'Right', size = 0.5, args = shell }
  mux.set_active_workspace('main')
end)

-- ============================================================
-- LAUNCH MENU  (LEADER+s → fuzzy launcher)
-- ============================================================
config.launch_menu = {
  { label='WSL bash',            args={ 'wsl.exe' } },
  { label='PowerShell 7',        args={ 'pwsh.exe', '-NoLogo'                               } },
  { label='PowerShell 5',        args={ 'powershell.exe', '-NoLogo'                         } },
  { label='CMD',                 args={ 'cmd.exe'                                            } },
  { label='Git Bash',            args={ 'C:/Program Files/Git/bin/bash.exe', '--login'      } },
  { label='WSL | PowerShell',    args={ 'wsl.exe' } },
}

-- ============================================================
-- MISC
-- ============================================================
config.automatically_reload_config              = true
config.check_for_updates                        = true
config.check_for_updates_interval_seconds       = 86400
config.show_update_window                       = false
config.exit_behavior                            = 'CloseOnCleanExit'
config.exit_behavior_messaging                  = 'Verbose'
config.selection_word_boundary                  = ' \t\n{}[]()"\''
config.enable_kitty_keyboard                    = false  -- true breaks leader key on Windows
config.adjust_window_size_when_changing_font_size = false

return config

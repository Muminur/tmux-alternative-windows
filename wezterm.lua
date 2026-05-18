-- ============================================================
--  WezTerm — Full-Featured tmux-Alternative Config
--  Theme     : NeonDark / NeonLight (toggle: LEADER+Shift+T)
--  Font      : FiraCode Nerd Font (ligatures on)
--  Shell     : PowerShell 7 (PS5 fallback)
--  Agents    : 7-pane agent grid workspace on startup
--  Work tab  : 2-pane side-by-side
--  Leader    : CTRL+B  (tmux default)
--  Mux       : built-in workspaces (session save/restore via JSON)
--  Sessions  : tmux-resurrect/continuum style save & restore
--              LEADER+Ctrl+S = save   LEADER+Ctrl+R = restore
--              LEADER+Ctrl+N = save named   LEADER+Ctrl+L = restore named
--              LEADER+Ctrl+D = delete named
--              Auto-saves every 15 min, auto-restores on start
--              Auto-prunes oldest sessions beyond 20 named saves
--  Layouts   : LEADER+A        = 7-pane agent grid
--              LEADER+Shift+2  = 2-pane side-by-side
--              LEADER+Shift+3  = 3-pane code layout
--              LEADER+Shift+4  = 4-pane 2x2 grid
--              LEADER+Shift+5  = main + sidebar (70/30, sidebar stacked)
--  Navigation: ALT+h/j/k/l or ALT+Arrows = pane nav (no leader)
--              ALT+1–9        = workspace switch by index
--              ALT+[  / ALT+] = pane history back / forward (20-entry stack)
--  Tabs      : LEADER+< / >   = reorder tabs
--              LEADER+!       = break pane out to new tab
--              Tab title shows git repo root (or CWD basename) when shell is active
--  Modes     : LEADER+:       = command palette
--              LEADER+R       = toggle read-only pane indicator
--              LEADER+Ctrl+H  = enter resize mode (h/j/k/l, ESC to exit)
--              LEADER+Shift+O = opacity toggle (solid ↔ acrylic transparent)
--  Workspace : LEADER+B       = toggle last workspace (like tmux L)
--              LEADER+W       = workspace dashboard (fuzzy, shows tab/pane counts)
--              LEADER+P       = project launcher (fuzzy-pick from dirs)
--              LEADER+Shift+S = dynamic SSH host picker (from ~/.ssh/config)
--              Status bar shows workspace index [N/M], accent color per workspace
--  Copy mode : full vim motions (^, H/M/L, f/F/t/T, ;/,)
--  Broadcast : LEADER+Ctrl+X  = one-shot send text to all panes
--              LEADER+Ctrl+Y  = toggle sync mode (continuous, SYNC badge in status bar)
--  Capture   : LEADER+Shift+C = copy full viewport text to clipboard
--  Safe paste: LEADER+V       = paste with dangerous-pattern check (prompts before pasting)
--  Dims      : inactive pane dimmed (saturation 85%, brightness 70%)
--  Git tabs  : tab title updates within 5s of directory change (OSC 7 support via cwd_notify)
--  Bell      : toast notification for bells in unfocused panes
--  Notify    : toast when long-running cmd (>15s) completes in bg pane
--  Sessions  : restore toast now shows workspace/tab/pane counts + invalid CWD count
--  Templates : LEADER+Ctrl+T = save template   LEADER+Ctrl+Shift+T = restore template
--  Logging   : LEADER+Shift+L = capture pane output to log file
--  CheatSheet: LEADER+/ = fuzzy-searchable keybinding reference
--  ConfigEdit: LEADER+Ctrl+E = open config in editor
--  SendKeys  : LEADER+Shift+K = send command to specific pane (no focus switch)
--  DeadPanes : LEADER+Ctrl+Q = auto-close all dead panes in active tab
--  ScrollLock: LEADER+Shift+F = freeze/unfreeze pane view (process continues)
--  WindowTitle: shows workspace › tab › process in title bar (ALT+TAB friendly)
--  Tint      : per-workspace subtle background tint (4% accent blend)
--  Status    : LEFT:  workspace [N/M] (accent color per workspace), WAIT, ZOOM, RESIZE, SYNC, RO,
--                      LOG, FREEZE, SAVED (green), ⏱Nm (orange, 5-15 min), STALE (red, >15 min), pane count
--              RIGHT: uptime, process, git branch + ✓ (clean) / ● (dirty), battery, clock
-- ============================================================

local wezterm = require 'wezterm'
local act     = wezterm.action
local mux     = wezterm.mux

local config  = wezterm.config_builder()

-- Per-window state (keyed by window_id)
local sync_windows  = {}  -- reserved for future sync-mode extensions
local sync_mode     = {}  -- window_id -> true when sync mode is active
local git_branch_cache = {} -- cwd -> { branch, dirty, repo_root, expires }
local readonly_panes = {} -- pane_id -> true for read-only panes
local current_theme = {}    -- window_id -> 'NeonDark' or 'NeonLight'
local prev_workspace = {}   -- window_id -> previous workspace name
local last_known_workspace = {}  -- window_id -> for prev_workspace tracking

-- Pane history navigation state (keyed by window_id for isolation)
local pane_history     = {}      -- window_id -> stack of pane_ids
local pane_history_pos = {}      -- window_id -> current position in stack
local MAX_PANE_HISTORY = 20
local last_tracked_pane = {}     -- window_id -> last pane_id

-- Enhancement 1: Floating/Scratch Pane state
local scratch_pane = {}  -- window_id -> pane_id

-- Enhancement 5: Per-Pane Labels state
local pane_labels = {}  -- pane_id -> label string

-- Enhancement 7: Last-Pane Toggle state (keyed by window_id for isolation)
local prev_active_pane = {}  -- window_id -> pane_id of previously active pane

-- Enhancement 14: Split ratio memory (per-workspace)
local split_ratios = {}  -- workspace -> { horizontal = 0.5, vertical = 0.5 }

-- Enhancement 15: Pane output capture state (badge shows for 30s after capture)
local logging_panes = {}  -- pane_id -> timestamp of last capture

-- Enhancement 16: Frozen/scroll-locked panes
local frozen_panes = {}  -- pane_id -> true

-- Enhancement 17: Session start time (read from lock file to survive config reloads)
local session_start_time = nil

-- Enhancement 12: Dangerous paste patterns (checked by LEADER+V safe paste)
local dangerous_paste_patterns = {
  'rm%s+%-rf%s+/',
  'DROP%s+TABLE',
  'DROP%s+DATABASE',
  ':%(%){%s*:%|:&%s*};:',
  '>%s*/dev/sda',
  'mkfs%.',
  'dd%s+if=',
  '%-%-no%-preserve%-root',
  'chmod%s+%-R%s+777%s+/',
  'curl.*|.*sh',
  'wget.*|.*sh',
}

-- ============================================================
-- NEON DARK COLOR SCHEME
-- ============================================================
local neon = {
  bg          = '#0d0d1a',
  bg_alt      = '#11111f',
  bg_panel    = '#14142a',
  bg_sel      = '#1e1e3f',
  fg          = '#ffffff',
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

-- ── Per-Workspace Accent Colors (Enhancement 7) ─────────────────
local workspace_accents = {
  neon.cyan, neon.magenta, neon.green, neon.yellow,
  neon.orange, neon.purple, neon.blue, neon.red,
}

local function workspace_accent(name)
  if not name or #name == 0 then return neon.cyan end
  local hash = 0
  for i = 1, #name do
    hash = (hash * 31 + string.byte(name, i)) % 256
  end
  return workspace_accents[(hash % #workspace_accents) + 1]
end

config.color_schemes = {
  ['NeonDark'] = {
    background    = neon.bg,
    foreground    = neon.fg,
    cursor_bg     = neon.cyan,
    cursor_border = neon.cyan,
    cursor_fg     = neon.black,
    selection_bg  = neon.bg_sel,
    selection_fg  = neon.white,
    scrollbar_thumb  = neon.cyan,
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
  ['NeonLight'] = {
    background    = '#f5f5fa',
    foreground    = '#1a1a2e',
    cursor_bg     = '#0077aa',
    cursor_border = '#0077aa',
    cursor_fg     = '#f5f5fa',
    selection_bg  = '#d0d0e8',
    selection_fg  = '#1a1a2e',
    scrollbar_thumb  = '#0077aa',
    split            = '#0077aa',
    compose_cursor   = '#cc6600',
    visual_bell      = '#cc0066',

    ansi = {
      '#e0e0e8', '#cc2244', '#007744', '#997700',
      '#0055aa', '#8800aa', '#007799', '#1a1a2e',
    },
    brights = {
      '#c0c0d0', '#ff4466', '#22aa66', '#bbaa22',
      '#3388cc', '#aa44cc', '#22aabb', '#0d0d1a',
    },

    tab_bar = {
      background = '#e8e8f0',
      active_tab = {
        bg_color  = '#0077aa', fg_color = '#f5f5fa',
        intensity = 'Bold',
      },
      inactive_tab       = { bg_color = '#d8d8e4', fg_color = '#555577' },
      inactive_tab_hover = { bg_color = '#c8c8d8', fg_color = '#1a1a2e' },
      new_tab            = { bg_color = '#e8e8f0', fg_color = '#0077aa' },
      new_tab_hover      = { bg_color = '#d8d8e4', fg_color = '#cc0066' },
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

config.window_background_opacity = 1.0   -- was 0.97; opacity < 1.0 forces compositor on every frame
config.text_background_opacity   = 1.0
config.win32_system_backdrop     = 'Disable'  -- was 'Acrylic'; Acrylic blur is the #1 typing-lag cause on Windows

config.window_decorations = 'TITLE | RESIZE'
config.window_padding = { left = 6, right = '2cell', top = 4, bottom = 0 }

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
-- SHELL — PowerShell 7 (PS5 fallback)
-- ============================================================
local function find_pwsh()
  local paths = {
    'C:/Program Files/PowerShell/7/pwsh.exe',
    'C:/Program Files/PowerShell/7-preview/pwsh.exe',
  }
  for _, p in ipairs(paths) do
    local f = io.open(p, 'r')
    if f then f:close(); return p end
  end
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
-- SSH DOMAINS  — add your servers here
-- ============================================================
config.ssh_domains = {
  -- { name = 'dev-server',  remote_address = '10.0.0.10',        username = 'ubuntu' },
  -- { name = 'prod',        remote_address = 'prod.example.com', username = 'deploy' },
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
  '[0-9a-f]{12}',
  '\\bAgent-[0-9]+\\b',
}

-- ============================================================
-- MOUSE BINDINGS
-- ============================================================
config.mouse_bindings = {
  { event = { Down = { streak=1, button='Right'  } }, mods='NONE',
    action = act.PasteFrom 'Clipboard' },
  { event = { Up   = { streak=1, button='Left'   } }, mods='CTRL',
    action = act.OpenLinkAtMouseCursor },
  { event = { Down = { streak=1, button='Middle' } }, mods='NONE',
    action = act.PasteFrom 'PrimarySelection' },
  { event = { Down = { streak=3, button='Left'   } }, mods='NONE',
    action = act.SelectTextAtMouseCursor 'Line' },
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
-- SESSION PERSISTENCE  (tmux-resurrect + tmux-continuum style)
--
--   Policy mirrors tmux-resurrect / tmux-continuum:
--     - Manual save:    LEADER + Ctrl+S
--     - Named save:     LEADER + Ctrl+N  (saves to <name>.json)
--     - Named restore:  LEADER + Ctrl+L  (fuzzy-pick from saved names)
--     - Named delete:   LEADER + Ctrl+D  (fuzzy-pick and delete)
--     - Manual restore: LEADER + Ctrl+R
--     - Auto-save:      every 15 minutes (AUTOSAVE_SECS)
--     - Auto-restore:   on mux startup if a save file exists
--
--   Save file: %USERPROFILE%\.wezterm_sessions\last.json
--   Saves: workspace names, active workspace, tab titles, pane CWDs, pane layout
-- ============================================================

local SESSION_DIR   = wezterm.home_dir .. '/.wezterm_sessions'
local SESSION_FILE  = SESSION_DIR .. '/last.json'
local AUTOSAVE_SECS = 15 * 60   -- 15 minutes, matching tmux-continuum default

local last_save_time = nil  -- for status-bar SAVED indicator

-- ── Minimal JSON encoder ────────────────────────────────────
local function json_encode(v)
  local t = type(v)
  if     t == 'nil'     then return 'null'
  elseif t == 'boolean' then return tostring(v)
  elseif t == 'number'  then return tostring(v)
  elseif t == 'string'  then
    return '"' ..
      v:gsub('\\','\\\\'):gsub('"','\\"')
       :gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t') ..
      '"'
  elseif t == 'table' then
    if #v > 0 then
      local items = {}
      for _, item in ipairs(v) do items[#items+1] = json_encode(item) end
      return '[' .. table.concat(items, ',') .. ']'
    else
      local items = {}
      for k, val in pairs(v) do
        items[#items+1] = json_encode(tostring(k)) .. ':' .. json_encode(val)
      end
      return '{' .. table.concat(items, ',') .. '}'
    end
  end
  return 'null'
end

-- ── Minimal JSON decoder ────────────────────────────────────
local function json_decode(s)
  if not s or #s == 0 then return nil end
  local pos = 1

  local function skip()
    while pos <= #s and s:sub(pos,pos):match('%s') do pos = pos + 1 end
  end

  local parse_val  -- forward declaration

  local function parse_str()
    pos = pos + 1  -- skip opening "
    local buf = {}
    while pos <= #s do
      local c = s:sub(pos, pos)
      if c == '"' then pos = pos + 1; return table.concat(buf) end
      if c == '\\' then
        pos = pos + 1
        c = s:sub(pos, pos)
        if c == 'u' then
          local hex = s:sub(pos + 1, pos + 4)
          pos = pos + 4
          local code = tonumber(hex, 16)
          if code then
            if code < 0x80 then
              buf[#buf+1] = string.char(code)
            elseif code < 0x800 then
              buf[#buf+1] = string.char(0xC0 + math.floor(code / 64), 0x80 + (code % 64))
            else
              buf[#buf+1] = string.char(0xE0 + math.floor(code / 4096), 0x80 + math.floor((code % 4096) / 64), 0x80 + (code % 64))
            end
          else
            buf[#buf+1] = '?'
          end
        else
          local esc = { ['"']='"', ['\\']='\\', ['/']='/',  n='\n', r='\r', t='\t', b='\b', f='\f' }
          buf[#buf+1] = esc[c] or c
        end
      else
        buf[#buf+1] = c
      end
      pos = pos + 1
    end
    return table.concat(buf)
  end

  local function parse_num()
    local start = pos
    if s:sub(pos,pos) == '-' then pos = pos + 1 end
    while pos <= #s and s:sub(pos,pos):match('%d') do pos = pos + 1 end
    if pos <= #s and s:sub(pos,pos) == '.' then
      pos = pos + 1
      while pos <= #s and s:sub(pos,pos):match('%d') do pos = pos + 1 end
    end
    if pos <= #s and s:sub(pos,pos):lower() == 'e' then
      pos = pos + 1
      if s:sub(pos,pos):match('[+-]') then pos = pos + 1 end
      while pos <= #s and s:sub(pos,pos):match('%d') do pos = pos + 1 end
    end
    return tonumber(s:sub(start, pos - 1))
  end

  local function parse_arr()
    pos = pos + 1; skip()
    local arr = {}
    if s:sub(pos,pos) == ']' then pos = pos + 1; return arr end
    while true do
      arr[#arr+1] = parse_val()
      skip()
      if s:sub(pos,pos) == ']' then pos = pos + 1; return arr end
      pos = pos + 1; skip()  -- skip comma
    end
  end

  local function parse_obj()
    pos = pos + 1; skip()
    local obj = {}
    if s:sub(pos,pos) == '}' then pos = pos + 1; return obj end
    while true do
      local key = parse_str(); skip()
      pos = pos + 1; skip()  -- skip colon
      obj[key] = parse_val()
      skip()
      if s:sub(pos,pos) == '}' then pos = pos + 1; return obj end
      pos = pos + 1; skip()  -- skip comma
    end
  end

  parse_val = function()
    skip()
    local c = s:sub(pos, pos)
    if     c == '"' then return parse_str()
    elseif c == '[' then return parse_arr()
    elseif c == '{' then return parse_obj()
    elseif c == 't' then pos = pos + 4; return true
    elseif c == 'f' then pos = pos + 5; return false
    elseif c == 'n' then pos = pos + 4; return nil
    else                 return parse_num()
    end
  end

  local ok, result = pcall(parse_val)
  return ok and result or nil
end

-- ── Helpers ──────────────────────────────────────────────────
local function ensure_session_dir()
  local dir = SESSION_DIR:gsub('/', '\\')
  os.execute('cmd /c if not exist "' .. dir .. '" mkdir "' .. dir .. '" 2>nul')
end

local function normalize_cwd(cwd_obj)
  if not cwd_obj then return '' end
  local path = cwd_obj.file_path or tostring(cwd_obj)
  path = path:gsub('^/([A-Za-z]:)', '%1')
  path = path:gsub('[/\\]+$', '')
  return path
end

-- Enhancement 9: Windows-only path existence check
-- Uses the NUL device trick for directories (no spawning required).
local function path_exists(path)
  if not path or #path == 0 then return false end
  -- Windows directory check: open path\NUL (a magic file that always exists inside any real dir)
  local f = io.open(path .. '\\NUL', 'r')
  if f then f:close(); return true end
  -- Fallback: try opening as a regular file
  f = io.open(path, 'r')
  if f then f:close(); return true end
  return false
end

-- Enhancement 14: Split ratio helpers
local function get_split_ratio(direction)
  local ok_ws, ws = pcall(mux.get_active_workspace)
  local workspace = (ok_ws and ws) or 'default'
  local ratios = split_ratios[workspace]
  if not ratios then return 0.5 end
  return direction == 'Right' and (ratios.horizontal or 0.5) or (ratios.vertical or 0.5)
end

local function set_split_ratio(direction, ratio)
  local ok_ws, ws = pcall(mux.get_active_workspace)
  local workspace = (ok_ws and ws) or 'default'
  if not split_ratios[workspace] then split_ratios[workspace] = {} end
  if direction == 'Right' then
    split_ratios[workspace].horizontal = ratio
  else
    split_ratios[workspace].vertical = ratio
  end
end

-- ── List named session files ──────────────────────────────────
-- Returns table of base names (without .json) from the session dir,
-- excluding the reserved slots: last, prev, and any .tmp files.
local function list_session_files()
  local sessions = {}
  local dir = SESSION_DIR:gsub('/', '\\')
  local f = io.popen('cmd /c dir /b "' .. dir .. '\\*.json" 2>nul')
  if not f then return sessions end
  for line in f:lines() do
    line = line:gsub('%s+$', '')
    local name = line:match('^(.+)%.json$')
    if name and name ~= 'last' and name ~= 'prev' then
      sessions[#sessions+1] = name
    end
  end
  f:close()
  return sessions
end

-- ── Auto-prune named sessions (keep newest MAX_NAMED_SESSIONS) ──
local MAX_NAMED_SESSIONS = 20

local function prune_named_sessions()
  local dir = SESSION_DIR:gsub('/', '\\')
  local entries = {}
  local f = io.popen('cmd /c dir /b /o-d "' .. dir .. '\\*.json" 2>nul')
  if not f then return end
  for line in f:lines() do
    line = line:gsub('%s+$', '')
    local name = line:match('^(.+)%.json$')
    if name and name ~= 'last' and name ~= 'prev' then
      entries[#entries+1] = name
    end
  end
  f:close()
  if #entries <= MAX_NAMED_SESSIONS then return end
  for i = MAX_NAMED_SESSIONS + 1, #entries do
    local path = SESSION_DIR .. '/' .. entries[i] .. '.json'
    pcall(os.remove, path)
  end
end

-- ── Initialize session start time (survives config reloads) ──
local function init_session_start()
  if session_start_time then return end
  local lock_path = wezterm.home_dir .. '\\.wezterm_startup.lock'
  local f = io.open(lock_path, 'r')
  if f then
    local ts = tonumber(f:read('*l') or '0') or 0
    f:close()
    -- Only trust the lock timestamp if it's within 60s (same WezTerm launch)
    if ts > 0 and (os.time() - ts) < 60 then session_start_time = ts; return end
  end
  session_start_time = os.time()
  -- Write fresh timestamp so config reloads within the same session reuse it
  local wf = io.open(lock_path, 'w')
  if wf then wf:write(tostring(session_start_time)); wf:close() end
end
init_session_start()

-- ── List workspace template files ────────────────────────────
local function list_template_files()
  local templates = {}
  local dir = (SESSION_DIR .. '/templates'):gsub('/', '\\')
  local f = io.popen('cmd /c dir /b "' .. dir .. '\\*.json" 2>nul')
  if not f then return templates end
  for line in f:lines() do
    line = line:gsub('%s+$', '')
    local name = line:match('^(.+)%.json$')
    if name then templates[#templates+1] = name end
  end
  f:close()
  return templates
end

-- ── Hex color blend helper (for per-workspace background tint) ──
local function hex_blend(base_hex, accent_hex, factor)
  local function parse(h)
    h = h:gsub('#', '')
    return tonumber(h:sub(1,2), 16), tonumber(h:sub(3,4), 16), tonumber(h:sub(5,6), 16)
  end
  local br, bg, bb = parse(base_hex)
  local ar, agr, ab = parse(accent_hex)
  local r = math.floor(br + (ar - br) * factor)
  local g = math.floor(bg + (agr - bg) * factor)
  local b = math.floor(bb + (ab - bb) * factor)
  return string.format('#%02x%02x%02x', r, g, b)
end

-- ── Save current session ──────────────────────────────────────
-- dest_file: optional path; defaults to SESSION_FILE (last.json).
-- Only the main slot (last.json) rotates prev.json and updates last_save_time.
local function do_save_session(dest_file)
  ensure_session_dir()
  local is_main = (dest_file == nil)
  dest_file = dest_file or SESSION_FILE

  local session = {
    version          = 2,
    saved_at         = os.time(),
    active_workspace = mux.get_active_workspace(),  -- Enhancement 7
    workspaces       = {},
  }

  local ok_names, names = pcall(mux.get_workspace_names)
  if not (ok_names and names) then return false end

  local ok_wins, all_wins = pcall(mux.all_windows)
  if not (ok_wins and all_wins) then return false end

  for _, ws_name in ipairs(names) do
    local ws_data = { name = ws_name, windows = {} }

    for _, win in ipairs(all_wins) do
      local ok_ws, win_ws = pcall(function() return win:get_workspace() end)
      if not (ok_ws and win_ws == ws_name) then goto next_win end

      local win_data = { tabs = {} }
      local ok_tabs, tabs = pcall(function() return win:tabs() end)

      if ok_tabs and tabs then
        for _, tab in ipairs(tabs) do
          local tab_data = { title = tab:get_title() or '', panes = {} }

          local ok_pi, panes_info = pcall(function() return tab:panes_with_info() end)
          if ok_pi and panes_info then
            for _, pinfo in ipairs(panes_info) do
              local cwd = ''
              local ok_cwd, cwd_obj = pcall(function()
                return pinfo.pane:get_current_working_dir()
              end)
              if ok_cwd then cwd = normalize_cwd(cwd_obj) end

              table.insert(tab_data.panes, {
                index     = pinfo.index,
                cwd       = cwd,
                left      = pinfo.left,
                top       = pinfo.top,
                width     = pinfo.width,
                height    = pinfo.height,
                is_active = pinfo.is_active,
              })
            end
          end

          table.insert(win_data.tabs, tab_data)
        end
      end

      table.insert(ws_data.windows, win_data)
      break  -- one mux window per workspace

      ::next_win::
    end

    table.insert(session.workspaces, ws_data)
  end

  -- Atomic write: .tmp → rotate prev → rename to dest
  local tmp_file = dest_file .. '.tmp'
  local ok_write = pcall(function()
    local f = assert(io.open(tmp_file, 'w'))
    f:write(json_encode(session))
    f:close()
    -- Only rotate prev.json for the main save slot
    if is_main then
      local prev_file = SESSION_DIR .. '/prev.json'
      local existing = io.open(dest_file, 'r')
      if existing then
        existing:close()
        os.remove(prev_file)       -- Windows: os.rename fails if target exists
        os.rename(dest_file, prev_file)
      end
    end
    os.remove(dest_file)           -- Windows: os.rename fails if target exists
    os.rename(tmp_file, dest_file)
  end)

  if ok_write and is_main then last_save_time = os.time() end
  if ok_write and not is_main then pcall(prune_named_sessions) end
  return ok_write
end

-- ── Restore panes inside one tab ─────────────────────────────
local function restore_panes(first_pane, panes_data, shell)
  if not panes_data or #panes_data == 0 then return end

  local prev_pane = first_pane
  for i = 2, #panes_data do
    local p    = panes_data[i]
    local cwd  = p.cwd or ''
    local prev = panes_data[i - 1]

    local direction = 'Right'
    if prev and p.top ~= nil and prev.top ~= nil and p.top > prev.top then
      direction = 'Bottom'
    end

    local split_args = { direction = direction, args = shell }
    if #cwd > 0 then split_args.cwd = cwd end

    local ok_s, new_pane = pcall(function() return prev_pane:split(split_args) end)
    if ok_s and new_pane then
      prev_pane = new_pane
    end
  end
end

-- ── Restore full session from save file ──────────────────────
local function do_restore_session(shell, file_path)
  local f = io.open(file_path or SESSION_FILE, 'r')
  if not f then return false, nil end
  local content = f:read('*a')
  f:close()

  local session = json_decode(content)
  if not (session and session.workspaces and #session.workspaces > 0) then
    return false, nil
  end

  -- Skip restore if session is trivial (single pane) — let the default 2-pane layout kick in
  local total_panes = 0
  for _, ws in ipairs(session.workspaces) do
    for _, win in ipairs(ws.windows or {}) do
      for _, tab in ipairs(win.tabs or {}) do
        total_panes = total_panes + #(tab.panes or {})
      end
    end
  end
  if total_panes <= 1 then return false, nil end

  -- Enhancement 9: track restore stats
  local stats = { workspaces = 0, tabs = 0, panes = 0, invalid_cwds = 0 }
  local any_restored = false

  for _, ws in ipairs(session.workspaces) do
    if not (ws.windows and #ws.windows > 0) then goto next_ws end
    local win_data = ws.windows[1]
    if not (win_data.tabs and #win_data.tabs > 0) then goto next_ws end

    local first_tab  = win_data.tabs[1]
    local first_cwd  = ''
    if first_tab.panes and first_tab.panes[1] then
      first_cwd = first_tab.panes[1].cwd or ''
    end

    local spawn_args = { workspace = ws.name, args = shell }
    if #first_cwd > 0 then
      if path_exists(first_cwd) then
        spawn_args.cwd = first_cwd
      else
        stats.invalid_cwds = stats.invalid_cwds + 1
        spawn_args.cwd = wezterm.home_dir
      end
    end

    local ok_spawn, tab, first_pane, window = pcall(function()
      return mux.spawn_window(spawn_args)
    end)
    if not ok_spawn then goto next_ws end

    tab:set_title(first_tab.title or ws.name)
    restore_panes(first_pane, first_tab.panes, shell)

    -- Enhancement 9: count stats for first tab
    stats.tabs = stats.tabs + 1
    if first_tab.panes then
      for _, p in ipairs(first_tab.panes) do
        stats.panes = stats.panes + 1
        if p.cwd and #p.cwd > 0 and not path_exists(p.cwd) then
          stats.invalid_cwds = stats.invalid_cwds + 1
        end
      end
    end

    for j = 2, #win_data.tabs do
      local tab_data = win_data.tabs[j]
      local tab_cwd  = ''
      if tab_data.panes and tab_data.panes[1] then
        tab_cwd = tab_data.panes[1].cwd or ''
      end

      local tab_args = { args = shell }
      if #tab_cwd > 0 then
        if path_exists(tab_cwd) then
          tab_args.cwd = tab_cwd
        else
          stats.invalid_cwds = stats.invalid_cwds + 1
          tab_args.cwd = wezterm.home_dir
        end
      end

      local ok_t, new_tab, new_pane = pcall(function()
        return window:spawn_tab(tab_args)
      end)
      if ok_t and new_tab then
        new_tab:set_title(tab_data.title or '')
        restore_panes(new_pane, tab_data.panes, shell)
        stats.tabs = stats.tabs + 1
        if tab_data.panes then
          for _, p in ipairs(tab_data.panes) do
            stats.panes = stats.panes + 1
            if p.cwd and #p.cwd > 0 and not path_exists(p.cwd) then
              stats.invalid_cwds = stats.invalid_cwds + 1
            end
          end
        end
      end
    end

    stats.workspaces = stats.workspaces + 1
    any_restored = true

    ::next_ws::
  end

  -- Enhancement 7: restore to the saved active workspace
  if any_restored then
    local target_ws = session.active_workspace
    if not target_ws and session.workspaces and session.workspaces[1] then
      target_ws = session.workspaces[1].name
    end
    if target_ws then
      pcall(mux.set_active_workspace, target_ws)
    end
  end

  return any_restored, stats
end

-- ── Auto-save loop  (tmux-continuum style) ───────────────────
local function start_autosave()
  pcall(function()
    wezterm.time.call_after(AUTOSAVE_SECS, function()
      do_save_session()
      start_autosave()
    end)
  end)
end

-- ============================================================
-- GIT INFO HELPER  (Enhancement 2 / 5 / 8)
-- Cached for 30 seconds per directory to avoid spawning git
-- on every status-bar repaint (~1 s interval).
-- Returns {branch, dirty, repo_root} table (branch may be nil for non-git dirs).
-- Negative results (non-repo) are also cached so we don't re-spawn on every repaint.
-- ============================================================
local function get_git_info(cwd)
  if not cwd or #cwd == 0 then return { branch = nil, dirty = false, repo_root = nil } end
  local now    = os.time()
  local cached = git_branch_cache[cwd]
  if cached and cached.expires > now then return cached end

  -- Evict cache if it grows too large
  local cache_size = 0
  for _ in pairs(git_branch_cache) do cache_size = cache_size + 1 end
  if cache_size > 200 then git_branch_cache = {} end

  -- Single combined git call: branch + toplevel in one process (saves ~100ms on Windows)
  local branch    = nil
  local repo_root = nil
  local ok1, success1, stdout1 = pcall(wezterm.run_child_process, {
    'git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD', '--show-toplevel',
  })
  if ok1 and success1 and stdout1 then
    local lines = {}
    for line in stdout1:gmatch('[^\r\n]+') do lines[#lines+1] = line end
    if lines[1] then
      local b = lines[1]:gsub('%s+$', '')
      if #b > 0 and b ~= 'HEAD' then branch = b end
    end
    if lines[2] then
      local root = lines[2]:gsub('%s+$', '')
      root = root:gsub('^/([A-Za-z]:)', '%1')
      if #root > 0 then repo_root = root end
    end
  end

  local dirty = false
  if branch then
    -- Dirty check: use --no-optional-locks to avoid contention, -uno to skip untracked
    local ok2, success2, stdout2 = pcall(wezterm.run_child_process, {
      'git', '--no-optional-locks', '-C', cwd, 'status', '--porcelain', '-uno',
    })
    if ok2 and success2 and stdout2 then
      dirty = (#stdout2:gsub('%s+$', '') > 0)
    end
  end

  -- 30s TTL reduces render-thread git spawns; cwd_notify invalidation handles fast updates
  local info = { branch = branch, dirty = dirty, repo_root = repo_root, expires = now + 30 }
  git_branch_cache[cwd] = info
  return info
end

-- ============================================================
-- LAYOUT FUNCTIONS  (Enhancement 6 + bug-fix: defined BEFORE config.keys)
-- ============================================================

-- 2-pane side-by-side (Code + Terminal)
local function spawn_layout_2pane(root_pane)
  root_pane:split { direction = 'Right', size = 0.5 }
end

-- 3-pane code layout (Editor left | Tests top-right | Logs bottom-right)
local function spawn_layout_3pane(root_pane)
  local right_top = root_pane:split { direction = 'Right', size = 0.40 }
  right_top:split { direction = 'Bottom', size = 0.50 }
end

-- 7-pane agent grid (was defined at bottom — moved here to fix forward-reference bug)
--
--   +----------+----------+----------+----------+
--   |  Agent 1 |  Agent 2 |  Agent 3 |  Agent 4 |  60%
--   +----------+----------+----------+----------+
--   |  Agent 5 |  Agent 6 |       Agent 7       |  40%
--   +----------+----------+---------------------+
local function spawn_agent_layout(root_pane)
  local bot1 = root_pane:split { direction = 'Bottom', size = 0.4 }

  local p2 = root_pane:split { direction = 'Right', size = 0.75 }
  local p3 = p2:split        { direction = 'Right', size = 0.67 }
  local p4 = p3:split        { direction = 'Right', size = 0.50 }

  local bot2 = bot1:split { direction = 'Right', size = 0.67 }
  local bot3 = bot2:split { direction = 'Right', size = 0.50 }

  local panes = { root_pane, p2, p3, p4, bot1, bot2, bot3 }
  for i, p in ipairs(panes) do
    p:send_text('$Host.UI.RawUI.WindowTitle = "Agent-' .. i .. '"; Clear-Host\r')
  end
end

-- 4-pane grid (2x2) — LEADER+Shift+4
local function spawn_layout_4grid(root_pane)
  local right = root_pane:split { direction = 'Right', size = 0.5 }
  root_pane:split { direction = 'Bottom', size = 0.5 }
  right:split { direction = 'Bottom', size = 0.5 }
end

-- Main + sidebar (large left, narrow right with two stacked panes) — LEADER+Shift+5
local function spawn_layout_main_sidebar(root_pane)
  local side_top = root_pane:split { direction = 'Right', size = 0.30 }
  side_top:split { direction = 'Bottom', size = 0.5 }
end

-- ============================================================
-- PROJECT WORKSPACE LAUNCHER
-- Scans known project roots, spawns workspace with 2-pane layout (editor + terminal)
-- ============================================================
local PROJECT_DIRS = {
  'L:\\DesktopApp',
  'C:\\Users\\Paula\\Projects',
  wezterm.home_dir .. '/repos',
}

local project_cache = { data = nil, expires = 0 }

local function scan_project_dirs()
  local now = os.time()
  if project_cache.data and project_cache.expires > now then
    return project_cache.data
  end

  local projects = {}
  for _, base in ipairs(PROJECT_DIRS) do
    local norm = base:gsub('/', '\\')
    local ok, success, stdout = pcall(wezterm.run_child_process, {
      'cmd', '/c', 'dir', '/b', '/ad', norm,
    })
    if ok and success and stdout then
      for line in stdout:gmatch('[^\r\n]+') do
        line = line:gsub('%s+$', '')
        if #line > 0 then
          projects[#projects+1] = { label = line, path = norm .. '\\' .. line }
        end
      end
    end
  end

  project_cache.data = projects
  project_cache.expires = now + 60
  return projects
end

-- ============================================================
-- SSH HOST PICKER  (parses ~/.ssh/config for Host entries)
-- ============================================================
local function parse_ssh_hosts()
  local hosts = {}
  local path  = wezterm.home_dir .. '/.ssh/config'
  local f     = io.open(path, 'r')
  if not f then return nil end
  for line in f:lines() do
    local host = line:match('^%s*[Hh]ost%s+(%S+)%s*$')
    if host and not host:find('[%*%?]') and host:sub(1,1) ~= '-' then
      hosts[#hosts+1] = host
    end
  end
  f:close()
  return hosts
end

-- ============================================================
-- Enhancement 2: Process Color Indicator lookup table
-- ============================================================
local process_colors = {
  ['ssh']     = '#ff4466', ['python']  = '#4fc3f7', ['python3'] = '#4fc3f7',
  ['node']    = '#00ff88', ['docker']  = '#b48eff', ['cargo']   = '#ff9f00',
  ['go']      = '#00ffe1', ['ruby']    = '#ff00aa', ['java']    = '#ffe566',
}

-- ============================================================
-- Enhancement: Keybinding Cheat Sheet data
-- ============================================================
local cheat_sheet = {
  { id = 'nav',    label = '[Navigation]  ALT+hjkl=pane  LEADER+hjkl=pane  ALT+1-9=workspace  ALT+[/]=history  LEADER+;=last pane  LEADER+B=last workspace' },
  { id = 'split',  label = '[Splits]  LEADER+|=right  LEADER+-=bottom  LEADER+Enter=smart  LEADER+Ctrl+Shift+R=set ratio' },
  { id = 'pane',   label = '[Panes]  LEADER+z=zoom  LEADER+x=close  LEADER+o=select  LEADER+q=swap  LEADER+`=scratch  LEADER+.=label  LEADER+Shift+F=scroll lock' },
  { id = 'tab',    label = '[Tabs]  LEADER+c=new  LEADER+n/p=next/prev  LEADER+1-9=jump  LEADER+<=>/>=reorder  LEADER+!=breakout  LEADER+,=rename' },
  { id = 'ws',     label = '[Workspace]  LEADER+w=launcher  LEADER+W=dashboard  LEADER+$=rename  LEADER+P=project  LEADER+Shift+S=SSH' },
  { id = 'sess',   label = '[Sessions]  LEADER+Ctrl+S=save  LEADER+Ctrl+R=restore  LEADER+Ctrl+N=named save  LEADER+Ctrl+L=named restore  LEADER+Ctrl+D=delete' },
  { id = 'layout', label = '[Layouts]  LEADER+A=7-agent  LEADER+Shift+2=2-pane  Shift+3=3-pane  Shift+4=4-grid  Shift+5=sidebar' },
  { id = 'bcast',  label = '[Broadcast]  LEADER+Ctrl+X=one-shot  LEADER+Ctrl+Y=sync mode  LEADER+Shift+K=send to pane' },
  { id = 'copy',   label = '[Copy/Search]  LEADER+[=copy mode  LEADER+f=search  LEADER+Space=quick select  LEADER+u=URLs  LEADER+Shift+C=capture viewport' },
  { id = 'misc',   label = '[Misc]  LEADER+Shift+T=theme  LEADER+Shift+O=opacity  LEADER+R=read-only indicator  LEADER+V=safe paste  LEADER+r=reload  LEADER+Ctrl+E=edit config  LEADER+Ctrl+Q=close dead  LEADER+Shift+L=log pane  LEADER+d=quit (saves first)' },
  { id = 'templ',  label = '[Templates]  LEADER+Ctrl+T=save template  LEADER+Ctrl+Shift+T=restore template' },
}

-- ============================================================
-- Enhancement 3: Workspace Template Save helper
-- ============================================================
local function save_workspace_template(name, window)
  local templates_dir = SESSION_DIR .. '/templates'
  local dir_win = templates_dir:gsub('/', '\\')
  os.execute('cmd /c if not exist "' .. dir_win .. '" mkdir "' .. dir_win .. '" 2>nul')

  local ws_name = mux.get_active_workspace()
  local ok_wins, all_wins = pcall(mux.all_windows)
  if not (ok_wins and all_wins) then return false end

  local ws_data = { name = ws_name, windows = {} }

  for _, win in ipairs(all_wins) do
    local ok_ws, win_ws = pcall(function() return win:get_workspace() end)
    if not (ok_ws and win_ws == ws_name) then goto next_tw end

    local win_data = { tabs = {} }
    local ok_tabs, tabs = pcall(function() return win:tabs() end)
    if ok_tabs and tabs then
      for _, tab in ipairs(tabs) do
        local tab_data = { title = tab:get_title() or '', panes = {} }
        local ok_pi, panes_info = pcall(function() return tab:panes_with_info() end)
        if ok_pi and panes_info then
          for _, pinfo in ipairs(panes_info) do
            local cwd = ''
            local ok_cwd, cwd_obj = pcall(function() return pinfo.pane:get_current_working_dir() end)
            if ok_cwd then cwd = normalize_cwd(cwd_obj) end
            table.insert(tab_data.panes, {
              index     = pinfo.index,
              cwd       = cwd,
              left      = pinfo.left,
              top       = pinfo.top,
              width     = pinfo.width,
              height    = pinfo.height,
              is_active = pinfo.is_active,
            })
          end
        end
        table.insert(win_data.tabs, tab_data)
      end
    end
    table.insert(ws_data.windows, win_data)
    break  -- one mux window per workspace
    ::next_tw::
  end

  local template = {
    version    = 2,
    saved_at   = os.time(),
    workspaces = { ws_data },
  }

  local dest = templates_dir .. '/' .. name .. '.json'
  local tmp  = dest .. '.tmp'
  local ok_write = pcall(function()
    local f = assert(io.open(tmp, 'w'))
    f:write(json_encode(template))
    f:close()
    os.remove(dest)
    os.rename(tmp, dest)
  end)
  return ok_write
end

-- ============================================================
-- KEY BINDINGS  (all tmux-equivalent + new enhancements)
-- ============================================================
config.keys = {

  -- ── ALT+ARROW / ALT+HJKL PANE NAVIGATION (no leader) ─────
  { key='h',          mods='ALT', action=act.ActivatePaneDirection 'Left'  },
  { key='j',          mods='ALT', action=act.ActivatePaneDirection 'Down'  },
  { key='k',          mods='ALT', action=act.ActivatePaneDirection 'Up'    },
  { key='l',          mods='ALT', action=act.ActivatePaneDirection 'Right' },
  { key='LeftArrow',  mods='ALT', action=act.ActivatePaneDirection 'Left'  },
  { key='DownArrow',  mods='ALT', action=act.ActivatePaneDirection 'Down'  },
  { key='UpArrow',    mods='ALT', action=act.ActivatePaneDirection 'Up'    },
  { key='RightArrow', mods='ALT', action=act.ActivatePaneDirection 'Right' },

  -- ── PANE SPLITTING (explicit cwd from active pane, ratio remembered per workspace) ─────────
  { key='|', mods='LEADER|SHIFT', action=wezterm.action_callback(function(_, pane)
      local cwd = pane:get_current_working_dir()
      local ratio = get_split_ratio('Right')
      pane:split { direction = 'Right', size = ratio, cwd = cwd and normalize_cwd(cwd) or nil }
  end)},
  { key='%', mods='LEADER|SHIFT', action=wezterm.action_callback(function(_, pane)
      local cwd = pane:get_current_working_dir()
      local ratio = get_split_ratio('Right')
      pane:split { direction = 'Right', size = ratio, cwd = cwd and normalize_cwd(cwd) or nil }
  end)},
  { key='-', mods='LEADER', action=wezterm.action_callback(function(_, pane)
      local cwd = pane:get_current_working_dir()
      local ratio = get_split_ratio('Bottom')
      pane:split { direction = 'Bottom', size = ratio, cwd = cwd and normalize_cwd(cwd) or nil }
  end)},
  { key='"', mods='LEADER|SHIFT', action=wezterm.action_callback(function(_, pane)
      local cwd = pane:get_current_working_dir()
      local ratio = get_split_ratio('Bottom')
      pane:split { direction = 'Bottom', size = ratio, cwd = cwd and normalize_cwd(cwd) or nil }
  end)},

  -- ── PANE NAVIGATION ────────────────────────────────────────
  { key='h',          mods='LEADER', action=act.ActivatePaneDirection 'Left'  },
  { key='j',          mods='LEADER', action=act.ActivatePaneDirection 'Down'  },
  { key='k',          mods='LEADER', action=act.ActivatePaneDirection 'Up'    },
  { key='l',          mods='LEADER', action=act.ActivatePaneDirection 'Right' },
  { key='LeftArrow',  mods='LEADER', action=act.ActivatePaneDirection 'Left'  },
  { key='DownArrow',  mods='LEADER', action=act.ActivatePaneDirection 'Down'  },
  { key='UpArrow',    mods='LEADER', action=act.ActivatePaneDirection 'Up'    },
  { key='RightArrow', mods='LEADER', action=act.ActivatePaneDirection 'Right' },

  -- ── PANE RESIZE (one-shot: LEADER+Shift, continuous: LEADER+Ctrl+H enters resize mode) ──
  { key='H', mods='LEADER', action=act.AdjustPaneSize { 'Left',  5 } },
  { key='J', mods='LEADER', action=act.AdjustPaneSize { 'Down',  5 } },
  { key='K', mods='LEADER', action=act.AdjustPaneSize { 'Up',    5 } },
  { key='L', mods='LEADER', action=act.AdjustPaneSize { 'Right', 5 } },
  { key='h', mods='LEADER|CTRL', action=act.ActivateKeyTable { name='resize_pane', one_shot=false } },

  -- ── PANE MANAGEMENT ────────────────────────────────────────
  { key='z', mods='LEADER', action=act.TogglePaneZoomState },
  { key='x', mods='LEADER', action=act.CloseCurrentPane { confirm=true } },
  { key='{', mods='LEADER|SHIFT', action=act.RotatePanes 'CounterClockwise' },
  { key='}', mods='LEADER|SHIFT', action=act.RotatePanes 'Clockwise' },
  { key='o', mods='LEADER', action=act.PaneSelect { alphabet = 'asdfghjkl' } },
  { key='q', mods='LEADER', action=act.PaneSelect { mode='SwapWithActiveKeepFocus' } },

  -- ── TAB REORDERING ──────────────────────────────────────────
  { key='<', mods='LEADER|SHIFT', action=act.MoveTabRelative(-1) },
  { key='>', mods='LEADER|SHIFT', action=act.MoveTabRelative(1)  },

  -- ── COMMAND PALETTE ────────────────────────────────────────
  { key=':', mods='LEADER|SHIFT', action=act.ActivateCommandPalette },

  -- ── PANE BREAK-OUT (promote pane to own tab, like tmux break-pane) ─
  { key='!', mods='LEADER|SHIFT', action=wezterm.action_callback(function(_, pane)
      pane:move_to_new_tab()
  end)},

  -- ── TABS (like tmux windows) ────────────────────────────────
  { key='c', mods='LEADER', action=act.SpawnTab 'CurrentPaneDomain' },
  { key='n', mods='LEADER', action=act.ActivateTabRelative(1)  },
  { key='p', mods='LEADER', action=act.ActivateTabRelative(-1) },
  { key='&', mods='LEADER|SHIFT', action=act.CloseCurrentTab { confirm=true } },
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
  { key='$', mods='LEADER|SHIFT', action=act.PromptInputLine {
      description = 'Rename workspace:',
      action = wezterm.action_callback(function(_, _, line)
        if line then mux.rename_workspace(mux.get_active_workspace(), line) end
      end),
  }},
  -- ── Enhancement 10: WORKSPACE DASHBOARD (LEADER+W) ───────────
  -- Replaces the old "new workspace name" prompt. Use LEADER+$ to rename, LEADER+w for launcher.
  { key='W', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      local ok_names, names = pcall(mux.get_workspace_names)
      if not (ok_names and names) or #names == 0 then
        pcall(function() window:toast_notification('WezTerm', 'No workspaces', nil, 2000) end)
        return
      end
      table.sort(names)
      local ok_wins, all_wins = pcall(mux.all_windows)
      local choices = {}
      for i, name in ipairs(names) do
        local tabs, panes = 0, 0
        if ok_wins and all_wins then
          for _, win in ipairs(all_wins) do
            local ok_ws, ws = pcall(function() return win:get_workspace() end)
            if ok_ws and ws == name then
              local ok_t, ts = pcall(function() return win:tabs() end)
              if ok_t and ts then
                tabs = #ts
                for _, t in ipairs(ts) do
                  local ok_p, ps = pcall(function() return t:panes() end)
                  if ok_p and ps then panes = panes + #ps end
                end
              end
              break
            end
          end
        end
        local marker = (name == mux.get_active_workspace()) and '● ' or '  '
        choices[#choices+1] = {
          id    = name,
          label = marker .. name .. '  [' .. tabs .. ' tabs, ' .. panes .. ' panes]',
        }
      end
      window:perform_action(act.InputSelector {
        title   = 'Workspace Dashboard',
        choices = choices,
        fuzzy   = true,
        action  = wezterm.action_callback(function(_, _, id, _)
          if id then mux.set_active_workspace(id) end
        end),
      }, pane)
  end)},

  -- ── LAST WORKSPACE TOGGLE (like tmux prefix+L) ────────────
  { key='B', mods='LEADER', action=wezterm.action_callback(function(window, _)
      local wid = window:window_id()
      if prev_workspace[wid] then
        local cur = mux.get_active_workspace()
        if prev_workspace[wid] ~= cur then
          local target = prev_workspace[wid]
          prev_workspace[wid] = cur
          last_known_workspace[wid] = target
          mux.set_active_workspace(target)
        end
      else
        pcall(function()
          window:toast_notification('WezTerm', 'No previous workspace', nil, 2000)
        end)
      end
  end)},

  -- ── PROJECT WORKSPACE LAUNCHER (LEADER+P) ──────────────────
  { key='P', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      local projects = scan_project_dirs()
      if #projects == 0 then
        pcall(function()
          window:toast_notification('WezTerm', 'No projects found in configured dirs', nil, 3000)
        end)
        return
      end
      local choices = {}
      for _, proj in ipairs(projects) do
        choices[#choices+1] = { id = proj.path, label = proj.label .. '  (' .. proj.path .. ')' }
      end
      window:perform_action(act.InputSelector {
        title   = 'Open Project Workspace',
        choices = choices,
        fuzzy   = true,
        action  = wezterm.action_callback(function(w, p, id, label)
          if id then
            local name = id:match('([^/\\]+)$') or 'project'
            local shell = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
            local tab, first_pane, new_win = mux.spawn_window {
              workspace = name, args = shell, cwd = id
            }
            tab:set_title(name)
            first_pane:split { direction = 'Right', size = 0.5, args = shell, cwd = id }
            mux.set_active_workspace(name)
          end
        end),
      }, pane)
  end)},

  -- ── ALT+1–9 WORKSPACE SWITCHING (sorted alphabetically) ─────
  { key='1', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and n[1] then mux.set_active_workspace(n[1]) end end)},
  { key='2', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and n[2] then mux.set_active_workspace(n[2]) end end)},
  { key='3', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and n[3] then mux.set_active_workspace(n[3]) end end)},
  { key='4', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and n[4] then mux.set_active_workspace(n[4]) end end)},
  { key='5', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and n[5] then mux.set_active_workspace(n[5]) end end)},
  { key='6', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and n[6] then mux.set_active_workspace(n[6]) end end)},
  { key='7', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and n[7] then mux.set_active_workspace(n[7]) end end)},
  { key='8', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and n[8] then mux.set_active_workspace(n[8]) end end)},
  { key='9', mods='ALT', action=wezterm.action_callback(function() local n = mux.get_workspace_names(); if n then table.sort(n) end; if n and #n > 0 then mux.set_active_workspace(n[#n]) end end)},

  -- ── THEME TOGGLE (NeonDark ↔ NeonLight) ────────────────────
  { key='T', mods='LEADER|SHIFT', action=wezterm.action_callback(function(window, _)
      local overrides = window:get_config_overrides() or {}
      local cur = overrides.color_scheme or 'NeonDark'
      local next_theme = cur == 'NeonDark' and 'NeonLight' or 'NeonDark'
      overrides.color_scheme = next_theme
      if next_theme == 'NeonLight' then
        overrides.window_frame = {
          font      = wezterm.font { family = 'FiraCode Nerd Font', weight = 'Bold' },
          font_size = 11.0,
          active_titlebar_bg            = '#e8e8f0',
          inactive_titlebar_bg          = '#d8d8e4',
          active_titlebar_fg            = '#0077aa',
          inactive_titlebar_fg          = '#555577',
          active_titlebar_border_bottom = '#0077aa',
          inactive_titlebar_border_bottom = '#d8d8e4',
          button_fg       = '#0077aa',
          button_bg       = '#e8e8f0',
          button_hover_fg = '#f5f5fa',
          button_hover_bg = '#0077aa',
        }
      else
        overrides.window_frame = nil
      end
      window:set_config_overrides(overrides)
      current_theme[window:window_id()] = next_theme
      pcall(function()
        window:toast_notification('WezTerm', 'Theme: ' .. next_theme, nil, 2000)
      end)
  end)},

  -- ── OPACITY TOGGLE (Solid ↔ Acrylic/Transparent) ───────────
  { key='O', mods='LEADER|SHIFT', action=wezterm.action_callback(function(window, _)
      local overrides = window:get_config_overrides() or {}
      local current = overrides.window_background_opacity or 1.0
      if current < 1.0 then
        overrides.window_background_opacity = 1.0
        overrides.win32_system_backdrop = 'Disable'
      else
        overrides.window_background_opacity = 0.85
        overrides.win32_system_backdrop = 'Acrylic'
      end
      window:set_config_overrides(overrides)
      pcall(function()
        window:toast_notification('WezTerm', 'Opacity: ' .. (overrides.window_background_opacity == 1.0 and 'Solid' or 'Transparent'), nil, 2000)
      end)
  end)},

  -- ── READ-ONLY PANE TOGGLE ──────────────────────────────────
  { key='R', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      local pid = pane:pane_id()
      if readonly_panes[pid] then
        readonly_panes[pid] = nil
        pcall(function()
          window:toast_notification('WezTerm', 'Pane ' .. pid .. ': read-only OFF', nil, 2000)
        end)
      else
        readonly_panes[pid] = true
        pcall(function()
          window:toast_notification('WezTerm', 'Pane ' .. pid .. ': READ-ONLY (visual indicator only)', nil, 2000)
        end)
      end
  end)},

  -- ── SESSION SAVE / RESTORE  (tmux-resurrect style) ─────────
  -- LEADER + Ctrl+S  →  save all workspaces to last.json
  { key='s', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, _)
      local ok = do_save_session()
      pcall(function()
        window:toast_notification(
          'WezTerm Sessions',
          ok and 'Session saved  ' or 'Save failed — check permissions',
          nil, 3000
        )
      end)
  end)},

  -- LEADER + Ctrl+R  →  restore workspaces from last save file
  { key='r', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, _)
      local shell = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
      local ok, stats = do_restore_session(shell)
      pcall(function()
        local msg = ok and ('Session restored  — '
          .. (stats and (stats.workspaces .. ' ws, ' .. stats.tabs .. ' tabs, ' .. stats.panes .. ' panes'
          .. (stats.invalid_cwds > 0 and (', ' .. stats.invalid_cwds .. ' bad CWDs') or '')) or ''))
          or 'No session file found'
        window:toast_notification('WezTerm Sessions', msg, nil, 4000)
      end)
  end)},

  -- LEADER + Ctrl+B  →  restore from previous backup (prev.json)
  { key='b', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, _)
      local shell    = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
      local prev_file = SESSION_DIR .. '/prev.json'
      local ok, stats = do_restore_session(shell, prev_file)
      pcall(function()
        local msg = ok and ('Backup restored — '
          .. (stats and (stats.workspaces .. ' ws, ' .. stats.tabs .. ' tabs, ' .. stats.panes .. ' panes'
          .. (stats.invalid_cwds > 0 and (', ' .. stats.invalid_cwds .. ' bad CWDs') or '')) or ''))
          or 'No backup session found'
        window:toast_notification('WezTerm Sessions', msg, nil, 4000)
      end)
  end)},

  -- ── NAMED SESSION MANAGEMENT  (Enhancement 1) ───────────────
  -- LEADER + Ctrl+N  →  save a named session
  { key='n', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, pane)
      window:perform_action(act.PromptInputLine {
        description = 'Save session as (name):',
        action = wezterm.action_callback(function(w, _, line)
          if line and #line > 0 then
            local safe = line:gsub('[^%w%-%_]', '_')
            local path = SESSION_DIR .. '/' .. safe .. '.json'
            local ok   = do_save_session(path)
            pcall(function()
              w:toast_notification(
                'WezTerm Sessions',
                ok and ('Saved as "' .. safe .. '"') or 'Save failed',
                nil, 3000
              )
            end)
          end
        end),
      }, pane)
  end)},

  -- LEADER + Ctrl+L  →  fuzzy-pick a named session and restore it
  { key='l', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, pane)
      local names = list_session_files()
      if #names == 0 then
        window:toast_notification('WezTerm Sessions', 'No named sessions found', nil, 3000)
        return
      end
      local choices = {}
      for _, name in ipairs(names) do
        choices[#choices+1] = { id = name, label = name }
      end
      window:perform_action(act.InputSelector {
        title   = 'Restore Named Session',
        choices = choices,
        fuzzy   = true,
        action  = wezterm.action_callback(function(w, _, id, _)
          if id then
            local shell = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
            local path  = SESSION_DIR .. '/' .. id .. '.json'
            local ok, stats = do_restore_session(shell, path)
            pcall(function()
              local msg = ok and ('Restored "' .. id .. '" — '
                .. (stats and (stats.workspaces .. ' ws, ' .. stats.tabs .. ' tabs, ' .. stats.panes .. ' panes'
                .. (stats.invalid_cwds > 0 and (', ' .. stats.invalid_cwds .. ' bad CWDs') or '')) or ''))
                or 'Restore failed'
              w:toast_notification('WezTerm Sessions', msg, nil, 4000)
            end)
          end
        end),
      }, pane)
  end)},

  -- LEADER + Ctrl+D  →  fuzzy-pick a named session and delete it
  { key='d', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, pane)
      local names = list_session_files()
      if #names == 0 then
        window:toast_notification('WezTerm Sessions', 'No named sessions found', nil, 3000)
        return
      end
      local choices = {}
      for _, name in ipairs(names) do
        choices[#choices+1] = { id = name, label = name }
      end
      window:perform_action(act.InputSelector {
        title   = 'Delete Named Session',
        choices = choices,
        fuzzy   = true,
        action  = wezterm.action_callback(function(w, _, id, _)
          if id then
            local path = SESSION_DIR .. '/' .. id .. '.json'
            local ok   = pcall(os.remove, path)
            pcall(function()
              w:toast_notification(
                'WezTerm Sessions',
                ok and ('Deleted "' .. id .. '"') or 'Delete failed',
                nil, 3000
              )
            end)
          end
        end),
      }, pane)
  end)},

  -- ── BROADCAST  (Enhancement 3) ──────────────────────────────
  -- LEADER + Ctrl+X  →  prompt for text, send to ALL panes in active tab
  { key='x', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, pane)
      window:perform_action(act.PromptInputLine {
        description = 'Broadcast to ALL panes (Enter to send):',
        action = wezterm.action_callback(function(w, _, line)
          if line then
            local tab   = w:active_tab()
            local panes = tab:panes()
            for _, p in ipairs(panes) do
              p:send_text(line .. '\r')
            end
            pcall(function()
              w:toast_notification(
                'WezTerm',
                'Broadcast sent to ' .. #panes .. ' pane(s)',
                nil, 2000
              )
            end)
          end
        end),
      }, pane)
  end)},

  -- ── SYNC MODE  (Enhancement 1) ───────────────────────────────
  -- LEADER + Ctrl+Y  →  toggle sync mode: type in prompt, sent to ALL panes
  { key='y', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, pane)
      local wid = window:window_id()
      if sync_mode[wid] then
        sync_mode[wid] = nil
        pcall(function()
          window:toast_notification('WezTerm', 'Sync mode OFF', nil, 2000)
        end)
      else
        sync_mode[wid] = true
        pcall(function()
          window:toast_notification('WezTerm', 'Sync mode ON — type in prompt, sent to all panes. LEADER+Ctrl+Y to stop.', nil, 3000)
        end)
        local function sync_loop(w, p)
          if not sync_mode[w:window_id()] then return end
          w:perform_action(act.PromptInputLine {
            description = 'SYNC> (Enter to send, empty to exit):',
            action = wezterm.action_callback(function(w2, _, line)
              if not line or #line == 0 then
                sync_mode[w2:window_id()] = nil
                pcall(function()
                  w2:toast_notification('WezTerm', 'Sync mode OFF', nil, 2000)
                end)
                return
              end
              local tab = w2:active_tab()
              local panes = tab:panes()
              for _, tp in ipairs(panes) do
                tp:send_text(line .. '\r')
              end
              -- Re-open prompt for next command
              wezterm.time.call_after(0.1, function()
                sync_loop(w2, p)
              end)
            end),
          }, p)
        end
        sync_loop(window, pane)
      end
  end)},

  -- ── DETACH / QUIT  (tmux LEADER+d — note: WezTerm has no detach, this quits) ──
  { key='d', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      do_save_session()
      window:perform_action(act.PromptInputLine {
        description = 'Quit WezTerm? Session auto-saved. Type "yes" to exit:',
        action = wezterm.action_callback(function(w, _, line)
          if line and line:lower() == 'yes' then
            w:perform_action(act.QuitApplication, pane)
          end
        end),
      }, pane)
  end)},

  -- ── SCROLLBACK IN EDITOR  (Enhancement 9) ───────────────────
  -- LEADER + e  →  open current selection (or try viewport) in $EDITOR
  { key='e', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      local text = window:get_selection_text_for_pane(pane)
      if not text or #text == 0 then
        -- Fallback: try wezterm CLI to grab viewport text
        local pane_id = tostring(pane:pane_id())
        local ok, success, stdout = pcall(wezterm.run_child_process, {
          'wezterm', 'cli', 'get-text', '--pane-id', pane_id,
        })
        if ok and success and stdout and #stdout > 0 then
          text = stdout
        else
          pcall(function()
            window:toast_notification(
              'WezTerm',
              'No selection — enter copy mode (LEADER+[), select text, then press LEADER+e',
              nil, 4000
            )
          end)
          return
        end
      end
      local tmp = SESSION_DIR .. '/scrollback_' .. os.time() .. '.txt'
      local f = io.open(tmp, 'w')
      if f then
        f:write(text)
        f:close()
        wezterm.open_with(tmp)
      end
  end)},

  -- ── COPY / SEARCH ───────────────────────────────────────────
  { key='[',     mods='LEADER', action=act.ActivateCopyMode },
  { key='f',     mods='LEADER', action=act.Search { CaseSensitiveString='' } },
  { key='Space', mods='LEADER', action=act.QuickSelect },
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
  { key='D', mods='LEADER', action=act.ShowLauncherArgs { flags='FUZZY|DOMAINS' } },

  -- ── SSH HOST PICKER (dynamic, from ~/.ssh/config) ─────────
  -- LEADER + Shift+S   →  fuzzy-pick SSH host and connect in new pane
  { key='S', mods='LEADER|SHIFT', action=wezterm.action_callback(function(window, pane)
      local hosts = parse_ssh_hosts()
      if not hosts then
        pcall(function()
          window:toast_notification('WezTerm', 'No ~/.ssh/config found', nil, 3000)
        end)
        return
      end
      if #hosts == 0 then
        pcall(function()
          window:toast_notification('WezTerm', 'No Host entries in ~/.ssh/config', nil, 3000)
        end)
        return
      end
      local choices = {}
      for _, h in ipairs(hosts) do
        choices[#choices+1] = { id = h, label = h }
      end
      window:perform_action(act.InputSelector {
        title   = 'SSH to Host',
        choices = choices,
        fuzzy   = true,
        action  = wezterm.action_callback(function(_, p, id, _)
          if id then
            p:split { direction = 'Right', args = { 'ssh', '--', id } }
          end
        end),
      }, pane)
  end)},

  -- ── LAYOUTS  (Enhancement 6) ─────────────────────────────────
  -- LEADER + A         →  7-pane agent grid
  { key='A', mods='LEADER', action=wezterm.action_callback(function(_, pane)
      spawn_agent_layout(pane)
  end)},
  -- LEADER + Shift+2   →  2-pane side-by-side
  { key='2', mods='LEADER|SHIFT', action=wezterm.action_callback(function(_, pane)
      spawn_layout_2pane(pane)
  end)},
  -- LEADER + Shift+3   →  3-pane code layout
  { key='3', mods='LEADER|SHIFT', action=wezterm.action_callback(function(_, pane)
      spawn_layout_3pane(pane)
  end)},
  -- LEADER + Shift+4   →  4-pane 2x2 grid
  { key='4', mods='LEADER|SHIFT', action=wezterm.action_callback(function(_, pane)
      spawn_layout_4grid(pane)
  end)},
  -- LEADER + Shift+5   →  main + sidebar (large left, narrow right stacked)
  { key='5', mods='LEADER|SHIFT', action=wezterm.action_callback(function(_, pane)
      spawn_layout_main_sidebar(pane)
  end)},

  -- ── MISC ─────────────────────────────────────────────────────
  { key='r', mods='LEADER',     action=act.ReloadConfiguration },
  { key='?', mods='LEADER|SHIFT', action=act.ShowLauncherArgs { flags='FUZZY|KEY_ASSIGNMENTS' } },
  { key='N', mods='CTRL|SHIFT', action=act.SpawnWindow },
  { key='T', mods='CTRL|SHIFT', action=act.ShowTabNavigator },
  { key='k', mods='CTRL|SHIFT', action=act.Multiple {
      act.ClearScrollback 'ScrollbackAndViewport',
      act.SendKey { key='l', mods='CTRL' },
  }},

  -- ── PANE HISTORY NAV  (Enhancement 4) ────────────────────────
  -- ALT+[  →  pane history back (per-window)
  { key='[', mods='ALT', action=wezterm.action_callback(function(window, _)
      local wid = window:window_id()
      local hist = pane_history[wid]
      local pos  = pane_history_pos[wid]
      if hist and pos and pos > 1 then
        pos = pos - 1
        pane_history_pos[wid] = pos
        local target_id = hist[pos]
        last_tracked_pane[wid] = target_id
        local tab = window:active_tab()
        local panes = tab:panes_with_info()
        for _, pinfo in ipairs(panes) do
          if pinfo.pane:pane_id() == target_id then
            pinfo.pane:activate()
            break
          end
        end
      end
  end)},
  -- ALT+]  →  pane history forward (per-window)
  { key=']', mods='ALT', action=wezterm.action_callback(function(window, _)
      local wid = window:window_id()
      local hist = pane_history[wid]
      local pos  = pane_history_pos[wid]
      if hist and pos and pos < #hist then
        pos = pos + 1
        pane_history_pos[wid] = pos
        local target_id = hist[pos]
        last_tracked_pane[wid] = target_id
        local tab = window:active_tab()
        local panes = tab:panes_with_info()
        for _, pinfo in ipairs(panes) do
          if pinfo.pane:pane_id() == target_id then
            pinfo.pane:activate()
            break
          end
        end
      end
  end)},

  -- ── Enhancement 1: FLOATING/SCRATCH PANE (LEADER+`) ──────────
  { key='`', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      local wid = window:window_id()
      local existing_id = scratch_pane[wid]
      if existing_id then
        local found = false
        local ok_mux, mux_win = pcall(function() return window:mux_window() end)
        if ok_mux and mux_win then
          local ok_tabs, tabs = pcall(function() return mux_win:tabs() end)
          if ok_tabs and tabs then
            for _, t in ipairs(tabs) do
              local ok_pi, panes_info = pcall(function() return t:panes_with_info() end)
              if ok_pi and panes_info then
                for _, pinfo in ipairs(panes_info) do
                  if pinfo.pane:pane_id() == existing_id then
                    found = true
                    pinfo.pane:activate()
                    window:perform_action(act.CloseCurrentPane { confirm = false }, pinfo.pane)
                    break
                  end
                end
              end
              if found then break end
            end
          end
        end
        scratch_pane[wid] = nil
        if not found then
          local shell_args = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
          local new_pane = pane:split { direction = 'Bottom', size = 0.2, args = shell_args }
          scratch_pane[wid] = new_pane:pane_id()
        end
      else
        local shell_args = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
        local new_pane = pane:split { direction = 'Bottom', size = 0.2, args = shell_args }
        scratch_pane[wid] = new_pane:pane_id()
      end
  end)},

  -- ── Enhancement 3: WORKSPACE TEMPLATE SAVE (LEADER+Ctrl+T) ──
  { key='t', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, pane)
      window:perform_action(act.PromptInputLine {
        description = 'Save workspace template as (name):',
        action = wezterm.action_callback(function(w, _, line)
          if line and #line > 0 then
            local safe = line:gsub('[^%w%-%_]', '_')
            local ok   = save_workspace_template(safe, w)
            pcall(function()
              w:toast_notification(
                'WezTerm Templates',
                ok and ('Template saved as "' .. safe .. '"') or 'Template save failed',
                nil, 3000
              )
            end)
          end
        end),
      }, pane)
  end)},

  -- ── Enhancement 4: SMART SPLIT DIRECTION (LEADER+Enter) ──────
  { key='Enter', mods='LEADER', action=wezterm.action_callback(function(_, pane)
      local dims = pane:get_dimensions()
      local cwd = pane:get_current_working_dir()
      local cwd_path = cwd and normalize_cwd(cwd) or nil
      local direction = (dims.cols > dims.viewport_rows * 2) and 'Right' or 'Bottom'
      pane:split { direction = direction, cwd = cwd_path }
  end)},

  -- ── Enhancement 5: PANE LABEL/ANNOTATION (LEADER+.) ─────────
  { key='.', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      window:perform_action(act.PromptInputLine {
        description = 'Pane label (empty to clear):',
        action = wezterm.action_callback(function(_, _, line)
          if line and #line > 0 then
            pane_labels[pane:pane_id()] = line
          else
            pane_labels[pane:pane_id()] = nil
          end
        end),
      }, pane)
  end)},

  -- ── Enhancement 7: LAST-PANE TOGGLE (LEADER+;) ───────────────
  { key=';', mods='LEADER', action=wezterm.action_callback(function(window, _)
      local wid = window:window_id()
      if prev_active_pane[wid] then
        local tab = window:active_tab()
        local panes = tab:panes_with_info()
        for _, pinfo in ipairs(panes) do
          if pinfo.pane:pane_id() == prev_active_pane[wid] then
            pinfo.pane:activate()
            break
          end
        end
      end
  end)},

  -- ── Enhancement 8: COMMAND OUTPUT CAPTURE (LEADER+Shift+C) ───
  -- Captures the full viewport text of the active pane and copies to clipboard.
  { key='C', mods='LEADER|SHIFT', action=wezterm.action_callback(function(window, pane)
      local pane_id = tostring(pane:pane_id())
      local ok, success, stdout = pcall(wezterm.run_child_process, {
        'wezterm', 'cli', 'get-text', '--pane-id', pane_id,
      })
      if ok and success and stdout and #stdout > 0 then
        window:copy_to_clipboard(stdout, 'Clipboard')
        pcall(function()
          window:toast_notification('WezTerm', 'Viewport text copied to clipboard (' .. #stdout .. ' chars)', nil, 3000)
        end)
      else
        pcall(function()
          window:toast_notification('WezTerm', 'Failed to capture pane text', nil, 3000)
        end)
      end
  end)},

  -- ── Enhancement 12: SAFE PASTE (LEADER+V) ────────────────────
  -- Reads clipboard via PowerShell, checks against dangerous patterns,
  -- and prompts for confirmation before pasting if a match is found.
  { key='V', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      local ok, success, stdout = pcall(wezterm.run_child_process, {
        'powershell.exe', '-NoProfile', '-Command', 'Get-Clipboard'
      })
      if not (ok and success and stdout) then
        window:perform_action(act.PasteFrom 'Clipboard', pane)
        return
      end
      local dangerous = false
      for _, pat in ipairs(dangerous_paste_patterns) do
        if stdout:find(pat) then
          dangerous = true
          break
        end
      end
      if dangerous then
        window:perform_action(act.PromptInputLine {
          description = 'WARNING: dangerous content detected! Type "yes" to paste anyway:',
          action = wezterm.action_callback(function(w, p, line)
            if line and line:lower() == 'yes' then
              w:perform_action(act.PasteFrom 'Clipboard', p)
            else
              pcall(function()
                w:toast_notification('WezTerm', 'Paste cancelled', nil, 2000)
              end)
            end
          end),
        }, pane)
      else
        window:perform_action(act.PasteFrom 'Clipboard', pane)
      end
  end)},

  -- ── Enhancement 14: SET SPLIT RATIO (LEADER+Ctrl+Shift+R) ───
  -- Prompts for a decimal ratio (0.1–0.9) and stores it per workspace.
  -- Subsequent | / % / - / " splits will use the stored ratio.
  { key='R', mods='LEADER|CTRL|SHIFT', action=wezterm.action_callback(function(window, pane)
      window:perform_action(act.PromptInputLine {
        description = 'Split ratio for this workspace (0.1–0.9, default 0.5):',
        action = wezterm.action_callback(function(_, _, line)
          local ratio = tonumber(line)
          if ratio and ratio >= 0.1 and ratio <= 0.9 then
            set_split_ratio('Right',  ratio)
            set_split_ratio('Bottom', ratio)
            pcall(function()
              window:toast_notification('WezTerm', ('Split ratio set to %.2f'):format(ratio), nil, 2000)
            end)
          else
            pcall(function()
              window:toast_notification('WezTerm', 'Invalid ratio — must be 0.1 to 0.9', nil, 2000)
            end)
          end
        end),
      }, pane)
  end)},

  -- ── Enhancement 15: WORKSPACE TEMPLATE RESTORE (LEADER+Ctrl+Shift+T) ──
  { key='T', mods='LEADER|CTRL|SHIFT', action=wezterm.action_callback(function(window, pane)
      local templates = list_template_files()
      if #templates == 0 then
        pcall(function()
          window:toast_notification('WezTerm Templates', 'No templates found. Save one with LEADER+Ctrl+T.', nil, 3000)
        end)
        return
      end
      local choices = {}
      for _, name in ipairs(templates) do
        choices[#choices+1] = { id = name, label = name }
      end
      window:perform_action(act.InputSelector {
        title   = 'Restore Workspace Template',
        choices = choices,
        fuzzy   = true,
        action  = wezterm.action_callback(function(w, _, id, _)
          if id then
            local shell = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
            local path  = SESSION_DIR .. '/templates/' .. id .. '.json'
            local ok, stats = do_restore_session(shell, path)
            pcall(function()
              local msg = ok and ('Template "' .. id .. '" restored — '
                .. (stats and (stats.workspaces .. ' ws, ' .. stats.tabs .. ' tabs, ' .. stats.panes .. ' panes') or ''))
                or 'Template restore failed'
              w:toast_notification('WezTerm Templates', msg, nil, 4000)
            end)
          end
        end),
      }, pane)
  end)},

  -- ── Enhancement 16: PANE OUTPUT CAPTURE TO FILE (LEADER+Shift+L) ──
  { key='L', mods='LEADER|SHIFT', action=wezterm.action_callback(function(window, pane)
      local pane_id = pane:pane_id()
      local logs_dir = (SESSION_DIR .. '/logs'):gsub('/', '\\')
      os.execute('cmd /c if not exist "' .. logs_dir .. '" mkdir "' .. logs_dir .. '" 2>nul')
      local log_path = SESSION_DIR .. '/logs/pane_' .. pane_id .. '_' .. os.time() .. '.log'
      local ok_cap, success_cap, stdout_cap = pcall(wezterm.run_child_process, {
        'wezterm', 'cli', 'get-text', '--pane-id', tostring(pane_id),
      })
      if ok_cap and success_cap and stdout_cap and #stdout_cap > 0 then
        local f = io.open(log_path, 'w')
        if f then
          f:write('-- Pane ' .. pane_id .. ' captured at ' .. os.date('%Y-%m-%d %H:%M:%S') .. '\n')
          f:write(stdout_cap)
          f:close()
          logging_panes[pane_id] = os.time()
          pcall(function()
            window:toast_notification('WezTerm', 'Pane output saved to:\n' .. log_path, nil, 4000)
          end)
        end
      else
        pcall(function()
          window:toast_notification('WezTerm', 'Failed to capture pane output', nil, 3000)
        end)
      end
  end)},

  -- ── Enhancement 17: KEYBINDING CHEAT SHEET (LEADER+/) ─────────
  { key='/', mods='LEADER', action=wezterm.action_callback(function(window, pane)
      window:perform_action(act.InputSelector {
        title   = 'Keybinding Cheat Sheet (type to filter)',
        choices = cheat_sheet,
        fuzzy   = true,
        action  = wezterm.action_callback(function(_, _, _, _) end),
      }, pane)
  end)},

  -- ── Enhancement 18: QUICK CONFIG EDIT (LEADER+Ctrl+E) ─────────
  { key='e', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, _)
      local config_path = wezterm.config_dir .. '/wezterm.lua'
      local f = io.open(config_path, 'r')
      if f then
        f:close()
        pcall(wezterm.open_with, config_path)
      else
        local fallback = wezterm.home_dir .. '/.wezterm.lua'
        local f2 = io.open(fallback, 'r')
        if f2 then f2:close() end
        pcall(wezterm.open_with, f2 and fallback or config_path)
      end
      pcall(function()
        window:toast_notification('WezTerm', 'Opening config in editor', nil, 2000)
      end)
  end)},

  -- ── Enhancement 19: SEND-KEYS TO SPECIFIC PANE (LEADER+Shift+K) ──
  { key='K', mods='LEADER|SHIFT', action=wezterm.action_callback(function(window, pane)
      local tab = window:active_tab()
      local panes = tab:panes_with_info()
      if #panes < 2 then
        pcall(function()
          window:toast_notification('WezTerm', 'Only one pane in this tab', nil, 2000)
        end)
        return
      end
      local choices = {}
      for _, pinfo in ipairs(panes) do
        local pid = pinfo.pane:pane_id()
        local proc = ''
        local ok_p, p_name = pcall(function() return pinfo.pane:get_foreground_process_name() end)
        if ok_p and p_name then proc = p_name:match('([^/\\]+)$') or '' end
        local label_str = pane_labels[pid] and (' [' .. pane_labels[pid] .. ']') or ''
        local marker = pinfo.is_active and '● ' or '  '
        choices[#choices+1] = {
          id    = tostring(pid),
          label = marker .. 'Pane ' .. pinfo.index .. label_str .. '  (' .. proc .. ')',
        }
      end
      window:perform_action(act.InputSelector {
        title   = 'Send command to pane:',
        choices = choices,
        fuzzy   = true,
        action  = wezterm.action_callback(function(w, p, id, _)
          if id then
            local target_id = tonumber(id)
            w:perform_action(act.PromptInputLine {
              description = 'Command to send (Enter to execute):',
              action = wezterm.action_callback(function(w2, _, line)
                if line and #line > 0 then
                  local tab2 = w2:active_tab()
                  local panes2 = tab2:panes_with_info()
                  for _, pi in ipairs(panes2) do
                    if pi.pane:pane_id() == target_id then
                      pi.pane:send_text(line .. '\r')
                      pcall(function()
                        w2:toast_notification('WezTerm', 'Sent to pane ' .. target_id, nil, 2000)
                      end)
                      break
                    end
                  end
                end
              end),
            }, p)
          end
        end),
      }, pane)
  end)},

  -- ── Enhancement 20: AUTO-CLOSE DEAD PANES (LEADER+Ctrl+Q) ──────
  { key='q', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, _)
      local tab = window:active_tab()
      local ok_pi, panes_info = pcall(function() return tab:panes_with_info() end)
      if not (ok_pi and panes_info) then return end
      local dead_panes = {}
      for _, pinfo in ipairs(panes_info) do
        local ok_fp, fp = pcall(function() return pinfo.pane:get_foreground_process_name() end)
        local proc_empty = (not ok_fp) or (not fp) or (#fp == 0)
        if proc_empty then
          local ok_pt, ptitle = pcall(function() return pinfo.pane:get_title() end)
          if ok_pt and ptitle then
            local lower_title = ptitle:lower()
            if lower_title:find('completed') or lower_title:find('exited') then
              dead_panes[#dead_panes+1] = pinfo.pane
            end
          end
        end
      end
      if #dead_panes == 0 then
        pcall(function()
          window:toast_notification('WezTerm', 'No dead panes found', nil, 2000)
        end)
        return
      end
      local count = #dead_panes
      for i, dp in ipairs(dead_panes) do
        wezterm.time.call_after(0.2 * (i - 1), function()
          pcall(function() dp:activate() end)
          wezterm.time.call_after(0.05, function()
            pcall(function()
              window:perform_action(act.CloseCurrentPane { confirm = false }, dp)
            end)
          end)
        end)
      end
      pcall(function()
        window:toast_notification('WezTerm', 'Closing ' .. count .. ' dead pane(s)...', nil, 3000)
      end)
  end)},

  -- ── Enhancement 21: PANE SCROLL LOCK / FREEZE (LEADER+Shift+F) ──
  { key='F', mods='LEADER|SHIFT', action=wezterm.action_callback(function(window, pane)
      local pid = pane:pane_id()
      if frozen_panes[pid] then
        frozen_panes[pid] = nil
        window:perform_action(act.CopyMode 'Close', pane)
        pcall(function()
          window:toast_notification('WezTerm', 'Scroll lock OFF — pane ' .. pid, nil, 2000)
        end)
      else
        frozen_panes[pid] = true
        window:perform_action(act.ActivateCopyMode, pane)
        pcall(function()
          window:toast_notification('WezTerm', 'Scroll lock ON — pane ' .. pid .. ' (view frozen, process continues)', nil, 3000)
        end)
      end
  end)},
}

-- ============================================================
-- COPY MODE key table (full vim motions)
-- ============================================================
config.key_tables = {
  copy_mode = {
    { key='q',        mods='NONE', action=wezterm.action_callback(function(window, pane)
        frozen_panes[pane:pane_id()] = nil
        window:perform_action(act.CopyMode 'Close', pane)
    end)},
    { key='Escape',   mods='NONE', action=wezterm.action_callback(function(window, pane)
        frozen_panes[pane:pane_id()] = nil
        window:perform_action(act.CopyMode 'Close', pane)
    end)},
    { key='h',        mods='NONE', action=act.CopyMode 'MoveLeft'              },
    { key='j',        mods='NONE', action=act.CopyMode 'MoveDown'              },
    { key='k',        mods='NONE', action=act.CopyMode 'MoveUp'                },
    { key='l',        mods='NONE', action=act.CopyMode 'MoveRight'             },
    { key='w',        mods='NONE', action=act.CopyMode 'MoveForwardWord'       },
    { key='b',        mods='NONE', action=act.CopyMode 'MoveBackwardWord'      },
    { key='e',        mods='NONE', action=act.CopyMode 'MoveForwardWordEnd'    },
    { key='0',        mods='NONE', action=act.CopyMode 'MoveToStartOfLine'              },
    { key='^',        mods='SHIFT',action=act.CopyMode 'MoveToStartOfLineContent'      },
    { key='$',        mods='SHIFT',action=act.CopyMode 'MoveToEndOfLineContent'        },
    { key='H',        mods='NONE', action=act.CopyMode 'MoveToViewportTop'             },
    { key='M',        mods='NONE', action=act.CopyMode 'MoveToViewportMiddle'          },
    { key='L',        mods='NONE', action=act.CopyMode 'MoveToViewportBottom'          },
    { key='f',        mods='NONE', action=act.CopyMode { JumpForward  = { prev_char = false } } },
    { key='F',        mods='NONE', action=act.CopyMode { JumpBackward = { prev_char = false } } },
    { key='t',        mods='NONE', action=act.CopyMode { JumpForward  = { prev_char = true  } } },
    { key='T',        mods='NONE', action=act.CopyMode { JumpBackward = { prev_char = true  } } },
    { key=';',        mods='NONE', action=act.CopyMode 'JumpAgain'                     },
    { key=',',        mods='NONE', action=act.CopyMode 'JumpReverse'                   },
    { key='g',        mods='NONE', action=act.CopyMode 'MoveToScrollbackTop'           },
    { key='G',        mods='NONE', action=act.CopyMode 'MoveToScrollbackBottom'        },
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
  resize_pane = {
    { key='h',      mods='NONE', action=act.AdjustPaneSize { 'Left',  2 } },
    { key='j',      mods='NONE', action=act.AdjustPaneSize { 'Down',  2 } },
    { key='k',      mods='NONE', action=act.AdjustPaneSize { 'Up',    2 } },
    { key='l',      mods='NONE', action=act.AdjustPaneSize { 'Right', 2 } },
    { key='LeftArrow',  mods='NONE', action=act.AdjustPaneSize { 'Left',  2 } },
    { key='DownArrow',  mods='NONE', action=act.AdjustPaneSize { 'Down',  2 } },
    { key='UpArrow',    mods='NONE', action=act.AdjustPaneSize { 'Up',    2 } },
    { key='RightArrow', mods='NONE', action=act.AdjustPaneSize { 'Right', 2 } },
    { key='Escape', mods='NONE', action=act.PopKeyTable },
    { key='q',      mods='NONE', action=act.PopKeyTable },
    { key='Enter',  mods='NONE', action=act.PopKeyTable },
  },
}

-- ============================================================
-- STATUS BAR — LEFT: workspace, mode indicators, pane count
--              RIGHT: process, git, battery, clock
-- ============================================================

wezterm.on('update-status', function(window, pane)
  local wid = window:window_id()

  -- Track workspace changes for last-workspace toggle (per-window)
  local current_ws = mux.get_active_workspace()
  if last_known_workspace[wid] and current_ws ~= last_known_workspace[wid] then
    prev_workspace[wid] = last_known_workspace[wid]
  end
  last_known_workspace[wid] = current_ws

  -- Track pane focus for history navigation (Enhancement 4) and last-pane toggle (Enhancement 7)
  local current_pane_id = pane:pane_id()
  if current_pane_id ~= last_tracked_pane[wid] then
    if not pane_history[wid] then
      pane_history[wid] = { current_pane_id }
      pane_history_pos[wid] = 1
    else
      prev_active_pane[wid] = last_tracked_pane[wid]
      local hist = pane_history[wid]
      local pos  = pane_history_pos[wid] or #hist
      if pos < #hist then
        for i = #hist, pos + 1, -1 do
          table.remove(hist, i)
        end
      end
      hist[#hist + 1] = current_pane_id
      if #hist > MAX_PANE_HISTORY then
        table.remove(hist, 1)
      end
      pane_history_pos[wid] = #hist
    end
    last_tracked_pane[wid] = current_pane_id
  end

  -- Smart scrollbar: hide in alternate screen (vim, htop, etc.), reclaim right padding
  local overrides = window:get_config_overrides() or {}
  local ok_alt, is_alt = pcall(function() return pane:is_alt_screen_active() end)
  if ok_alt and is_alt then
    overrides.enable_scroll_bar = false
    overrides.window_padding    = { left = 6, right = 6, top = 4, bottom = 0 }
  else
    overrides.enable_scroll_bar = nil
    overrides.window_padding    = nil
  end

  -- Per-workspace background tint (subtle 4% blend of workspace accent color)
  -- Skip tint when transparency/acrylic is active to avoid painting over compositor effect
  local cur_opacity = overrides.window_background_opacity
  if not cur_opacity or cur_opacity >= 1.0 then
    local cur_scheme = overrides.color_scheme or 'NeonDark'
    local base_bg = cur_scheme == 'NeonLight' and '#f5f5fa' or neon.bg
    local accent = workspace_accent(current_ws)
    local tinted_bg = hex_blend(base_bg, accent, 0.04)
    overrides.background = {
      { source = { Color = tinted_bg }, width = '100%', height = '100%' },
    }
  else
    overrides.background = nil
  end

  window:set_config_overrides(overrides)

  -- ── LEFT STATUS: workspace [N/M] + mode indicators + pane count ──
  local left = {}

  local ws = mux.get_active_workspace()
  local ws_idx_str = ''
  local ok_ws_names, ws_names = pcall(mux.get_workspace_names)
  if ok_ws_names and ws_names then
    table.sort(ws_names)
    for i, name in ipairs(ws_names) do
      if name == ws then ws_idx_str = ' [' .. i .. '/' .. #ws_names .. ']'; break end
    end
  end
  left[#left+1] = wezterm.format {
    { Background = { Color = workspace_accent(ws) } },
    { Foreground = { Color = neon.black } },
    { Attribute  = { Intensity = 'Bold' } },
    { Text = '  ' .. ws .. ws_idx_str .. ' ' },
  }

  if window:leader_is_active() then
    left[#left+1] = wezterm.format {
      { Background = { Color = neon.magenta } },
      { Foreground = { Color = neon.black   } },
      { Attribute  = { Intensity = 'Bold'   } },
      { Text = '  WAIT  ' },
    }
  end

  local ok_pi, panes_info = pcall(function() return window:active_tab():panes_with_info() end)
  if ok_pi and panes_info then
    for _, pinfo in ipairs(panes_info) do
      if pinfo.is_active and pinfo.is_zoomed then
        left[#left+1] = wezterm.format {
          { Background = { Color = neon.yellow } },
          { Foreground = { Color = neon.black  } },
          { Attribute  = { Intensity = 'Bold'  } },
          { Text = '  ZOOM  ' },
        }
        break
      end
    end
  end

  local active_key_table = window:active_key_table()
  if active_key_table == 'resize_pane' then
    left[#left+1] = wezterm.format {
      { Background = { Color = neon.orange } },
      { Foreground = { Color = neon.black  } },
      { Attribute  = { Intensity = 'Bold'  } },
      { Text = '  RESIZE  ' },
    }
  end

  if sync_mode[window:window_id()] then
    left[#left+1] = wezterm.format {
      { Background = { Color = neon.red    } },
      { Foreground = { Color = neon.black  } },
      { Attribute  = { Intensity = 'Bold'  } },
      { Text = '  SYNC  ' },
    }
  end

  if readonly_panes[pane:pane_id()] then
    left[#left+1] = wezterm.format {
      { Background = { Color = neon.red   } },
      { Foreground = { Color = neon.black } },
      { Attribute  = { Intensity = 'Bold' } },
      { Text = '  RO  ' },
    }
  end

  local capture_ts = logging_panes[pane:pane_id()]
  if capture_ts then
    if os.time() - capture_ts < 30 then
      left[#left+1] = wezterm.format {
        { Background = { Color = neon.blue  } },
        { Foreground = { Color = neon.black } },
        { Attribute  = { Intensity = 'Bold' } },
        { Text = '  CAPTURED  ' },
      }
    else
      logging_panes[pane:pane_id()] = nil
    end
  end

  if frozen_panes[pane:pane_id()] then
    left[#left+1] = wezterm.format {
      { Background = { Color = neon.purple } },
      { Foreground = { Color = neon.black  } },
      { Attribute  = { Intensity = 'Bold'  } },
      { Text = '  FREEZE  ' },
    }
  end

  if last_save_time then
    local age = os.time() - last_save_time
    if age < 30 then
      -- SAVED badge: shows for 30s immediately after a save
      left[#left+1] = wezterm.format {
        { Background = { Color = neon.green } },
        { Foreground = { Color = neon.black } },
        { Attribute  = { Intensity = 'Bold' } },
        { Text = '  SAVED  ' },
      }
    elseif age > AUTOSAVE_SECS then
      -- STALE badge: last save was more than 15 min ago
      left[#left+1] = wezterm.format {
        { Background = { Color = neon.red   } },
        { Foreground = { Color = neon.black } },
        { Attribute  = { Intensity = 'Bold' } },
        { Text = '  STALE  ' },
      }
    elseif age > 300 then
      -- Age badge: 5–15 min since last save, show elapsed minutes
      local mins = math.floor(age / 60)
      left[#left+1] = wezterm.format {
        { Background = { Color = neon.orange } },
        { Foreground = { Color = neon.black  } },
        { Attribute  = { Intensity = 'Bold'  } },
        { Text = '  ⏱ ' .. mins .. 'm  ' },
      }
    end
  end

  local ok_tab, active_tab = pcall(function() return window:active_tab() end)
  if ok_tab and active_tab then
    local ok_panes, tab_panes = pcall(function() return active_tab:panes() end)
    if ok_panes and tab_panes and #tab_panes > 0 then
      left[#left+1] = wezterm.format {
        { Background = { Color = neon.bg_panel } },
        { Foreground = { Color = neon.yellow   } },
        { Text = '  ' .. #tab_panes .. 'p ' },
      }
    end

    -- Enhancement 5: show pane label if one is set for the active pane
    local pane_label = pane_labels[pane:pane_id()]
    if pane_label then
      left[#left+1] = wezterm.format {
        { Background = { Color = neon.bg_sel  } },
        { Foreground = { Color = neon.cyan    } },
        { Attribute  = { Intensity = 'Bold'   } },
        { Text = '  ' .. pane_label .. ' ' },
      }
    end

    -- Enhancement 6: dead pane detection
    local ok_pwi, panes_with_info = pcall(function() return active_tab:panes_with_info() end)
    if ok_pwi and panes_with_info then
      local has_dead = false
      for _, pinfo in ipairs(panes_with_info) do
        local ok_fp, fp = pcall(function() return pinfo.pane:get_foreground_process_name() end)
        local proc_empty = (not ok_fp) or (not fp) or (#fp == 0)
        if proc_empty then
          local ok_pt, ptitle = pcall(function() return pinfo.pane:get_title() end)
          if ok_pt and ptitle then
            local lower_title = ptitle:lower()
            if lower_title:find('completed') or lower_title:find('exited') then
              has_dead = true
              break
            end
          end
        end
      end
      if has_dead then
        left[#left+1] = wezterm.format {
          { Background = { Color = neon.orange } },
          { Foreground = { Color = neon.black  } },
          { Attribute  = { Intensity = 'Bold'  } },
          { Text = '  DEAD  ' },
        }
      end
    end
  end

  window:set_left_status(table.concat(left))

  -- ── RIGHT STATUS: uptime, process, git, battery, clock ──────
  local right = {}

  if session_start_time then
    local elapsed = os.time() - session_start_time
    local hours   = math.floor(elapsed / 3600)
    local mins    = math.floor((elapsed % 3600) / 60)
    local uptime_str = hours > 0 and string.format('↑%dh %dm', hours, mins) or string.format('↑%dm', mins)
    right[#right+1] = wezterm.format {
      { Background = { Color = neon.bg_panel } },
      { Foreground = { Color = neon.fg_dim   } },
      { Text = '  ' .. uptime_str .. ' ' },
    }
  end

  local ok_proc, proc = pcall(function() return pane:get_foreground_process_name() end)
  if not ok_proc then proc = '' end
  proc = proc or ''
  if proc ~= '' then
    proc = proc:match('([^/\\]+)$') or proc
    -- Enhancement 2: per-process color indicator
    local proc_key   = proc:lower():gsub('%.exe$', '')
    local proc_color = process_colors[proc_key] or neon.purple
    right[#right+1] = wezterm.format {
      { Background = { Color = neon.bg_panel } },
      { Foreground = { Color = proc_color    } },
      { Text = '  ' .. proc .. ' ' },
    }
  end

  local ok_cwd, cwd_obj = pcall(function() return pane:get_current_working_dir() end)
  if ok_cwd and cwd_obj then
    local cwd_path = normalize_cwd(cwd_obj)
    local git_info = get_git_info(cwd_path)
    if git_info.branch then
      local dirty_fg   = git_info.dirty and neon.red   or neon.green
      local dirty_icon = git_info.dirty and ' ●'       or ' ✓'
      right[#right+1] = wezterm.format {
        { Background = { Color = neon.bg_panel } },
        { Foreground = { Color = neon.yellow   } },
        { Text = '   ' .. git_info.branch },
        { Foreground = { Color = dirty_fg     } },
        { Text = dirty_icon .. ' ' },
      }
    end
  end

  local ok, bats = pcall(wezterm.battery_info)
  if ok and bats and #bats > 0 then
    for _, b in ipairs(bats) do
      local pct  = math.floor(b.state_of_charge * 100)
      local col  = pct > 30 and neon.green or neon.red
      local icon = b.state == 'Charging'
                 and wezterm.nerdfonts.md_battery_charging
                 or  wezterm.nerdfonts.md_battery_high
      right[#right+1] = wezterm.format {
        { Background = { Color = neon.bg_alt } },
        { Foreground = { Color = col         } },
        { Text = ' ' .. icon .. pct .. '% ' },
      }
    end
  end

  right[#right+1] = wezterm.format {
    { Background = { Color = neon.bg_alt } },
    { Foreground = { Color = neon.fg_dim } },
    { Text = '  ' .. wezterm.strftime '%a %d %b  %H:%M ' },
  }

  window:set_right_status(table.concat(right))
end)

-- ============================================================
-- TAB TITLE — shows CWD basename when process is a shell
-- ============================================================
local SHELL_PROCS = { ['pwsh.exe']=true, ['powershell.exe']=true, ['cmd.exe']=true,
  ['bash.exe']=true, ['bash']=true, ['zsh']=true, ['fish']=true, ['nu.exe']=true, ['wsl.exe']=true }

wezterm.on('format-tab-title', function(tab, _, _, _, _, max_width)
  local p     = tab.active_pane
  local title = (p.title and #p.title > 0) and p.title or 'shell'
  local idx   = tab.tab_index + 1

  local proc_name = (p.foreground_process_name or ''):match('([^/\\]+)$') or ''
  if SHELL_PROCS[proc_name:lower()] or proc_name == '' then
    local cwd = p.current_working_dir
    if cwd then
      -- Normalize CWD the same way as the status bar (strips leading /X: and trailing slashes)
      local cwd_path = normalize_cwd(cwd)
      -- Try git repo root first; fall back to CWD basename
      local git_info = get_git_info(cwd_path)
      if git_info.repo_root then
        local repo_name = git_info.repo_root:match('([^/\\]+)[/\\]*$')
        if repo_name and #repo_name > 0 then
          title = repo_name
        end
      else
        local basename = cwd_path:match('([^/\\]+)[/\\]*$')
        if basename and #basename > 0 then
          title = basename
        end
      end
    end
  end

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
-- WINDOW TITLE — shows workspace › tab › process for ALT+TAB clarity
-- ============================================================
wezterm.on('format-window-title', function(tab, pane, tabs, _, _)
  local ws = mux.get_active_workspace()
  local tab_title = tab.active_pane.title or 'shell'
  local proc = (tab.active_pane.foreground_process_name or ''):match('([^/\\]+)$') or ''

  local zoom = ''
  for _, p in ipairs(tab.panes) do
    if p.is_zoomed then zoom = ' [Z]'; break end
  end

  local pane_count = #tab.panes > 1 and (' (' .. #tab.panes .. 'p)') or ''
  local tab_count = #tabs > 1 and (' [' .. (tab.tab_index + 1) .. '/' .. #tabs .. ']') or ''

  if proc ~= '' and proc ~= tab_title then
    return ws .. ' › ' .. tab_title .. ' › ' .. proc .. zoom .. pane_count .. tab_count
  end
  return ws .. ' › ' .. tab_title .. zoom .. pane_count .. tab_count
end)

-- ============================================================
-- PANE CLOSE CLEANUP — garbage-collect stale per-pane state maps
-- ============================================================
wezterm.on('pane-focus-changed', function(window, _)
  local live_ids = {}
  local ok_mux, mux_win = pcall(function() return window:mux_window() end)
  if ok_mux and mux_win then
    local ok_tabs, tabs = pcall(function() return mux_win:tabs() end)
    if ok_tabs and tabs then
      for _, t in ipairs(tabs) do
        local ok_p, ps = pcall(function() return t:panes() end)
        if ok_p and ps then
          for _, p in ipairs(ps) do live_ids[p:pane_id()] = true end
        end
      end
    end
  end
  if not next(live_ids) then return end
  for pid, _ in pairs(pane_labels) do
    if not live_ids[pid] then pane_labels[pid] = nil end
  end
  for pid, _ in pairs(readonly_panes) do
    if not live_ids[pid] then readonly_panes[pid] = nil end
  end
  for pid, _ in pairs(frozen_panes) do
    if not live_ids[pid] then frozen_panes[pid] = nil end
  end
  for pid, _ in pairs(logging_panes) do
    if not live_ids[pid] then logging_panes[pid] = nil end
  end
end)

-- ============================================================
-- BELL NOTIFICATION — toast when a bell rings in an unfocused pane
-- To trigger on command completion, add to your PowerShell profile:
--   function prompt { [char]7 + "PS $($PWD.Path)> " }
-- ============================================================
wezterm.on('bell', function(window, pane)
  local active_pane = window:active_pane()
  if active_pane and active_pane:pane_id() ~= pane:pane_id() then
    local title = pane:get_title() or 'pane'
    pcall(function()
      window:toast_notification('WezTerm', 'Bell in: ' .. title, nil, 4000)
    end)
  end
end)

-- ============================================================
-- LONG-RUNNING COMMAND NOTIFICATION
-- Notifies when a command finishes after >15s in a non-focused pane.
-- Requires PowerShell profile hook (add to $PROFILE):
--   function prompt {
--     $duration = if ($global:__wez_cmd_start) {
--       ((Get-Date) - $global:__wez_cmd_start).TotalSeconds
--     } else { 0 }
--     if ($duration -gt 0) {
--       [Console]::Write("`e]1337;SetUserVar=cmd_duration=$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([int]$duration)))`a")
--     }
--     $global:__wez_cmd_start = Get-Date
--     "PS $($PWD.Path)> "
--   }
-- ============================================================
local CMD_NOTIFY_THRESHOLD = 15  -- seconds

wezterm.on('user-var-changed', function(window, pane, name, value)
  -- Enhancement 13: invalidate git cache on directory change for instant tab rename
  if name == 'cwd_notify' then
    local decoded = value
    pcall(function() decoded = wezterm.base64_decode(value) end)
    if decoded and #decoded > 0 then
      git_branch_cache[decoded] = nil  -- force immediate re-query on next format-tab-title
    end
    return
  end

  if name ~= 'cmd_duration' then return end
  local decoded = value
  pcall(function() decoded = wezterm.base64_decode(value) end)
  local duration = tonumber(decoded) or 0
  if duration < CMD_NOTIFY_THRESHOLD then return end

  local active_pane = window:active_pane()
  if active_pane and active_pane:pane_id() == pane:pane_id() then return end

  local title = pane:get_title() or 'pane'
  local mins  = math.floor(duration / 60)
  local secs  = duration % 60
  local time_str = mins > 0 and string.format('%dm %ds', mins, secs) or string.format('%ds', secs)
  pcall(function()
    window:toast_notification(
      'WezTerm — Command Finished',
      title .. ' completed after ' .. time_str,
      nil, 5000
    )
  end)
end)

-- ============================================================
-- CONFIG RELOAD TOAST
-- ============================================================
wezterm.on('window-config-reloaded', function(window, _)
  pcall(function()
    window:toast_notification('WezTerm', 'Config reloaded', nil, 2000)
  end)
end)

-- ============================================================
-- MUX STARTUP
--   Priority order (mirrors tmux-continuum behaviour):
--     1. Non-default workspace already exists → reattach, skip startup.
--     2. ~/.wezterm_sessions/last.json exists → auto-restore.
--     3. Otherwise → create default 'main' 2-pane workspace.
--   Auto-save timer started in all branches.
-- ============================================================
-- Cross-process duplicate-launch guard.
-- Each WezTerm process runs its own mux server and fires mux-startup independently.
-- A timestamp lock file lets a second process detect it started within 30 s of the
-- first and skip the full workspace spawn (preventing duplicate blank pane windows).
local STARTUP_LOCK = wezterm.home_dir .. '\\.wezterm_startup.lock'
local function is_duplicate_launch()
  local f = io.open(STARTUP_LOCK, 'r')
  if f then
    local ts = tonumber(f:read('*l') or '0') or 0
    f:close()
    if os.time() - ts < 30 then return true end
  end
  local wf = io.open(STARTUP_LOCK, 'w')
  if wf then wf:write(tostring(os.time())); wf:close() end
  return false
end

wezterm.on('mux-startup', function()
  local shell = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }

  -- Guard 1: another WezTerm process started within the last 30 s — skip spawning
  -- so we don't pollute with duplicate blank pane windows.
  if is_duplicate_launch() then
    start_autosave()
    return
  end

  -- Guard 2: if any non-default workspace exists the mux server
  -- is already populated — do not re-run startup logic.
  local ok_names, names = pcall(mux.get_workspace_names)
  if ok_names and names then
    for _, name in ipairs(names) do
      if name ~= 'default' then
        pcall(mux.set_active_workspace, name)
        start_autosave()
        return
      end
    end
  end

  -- Check if a meaningful saved session exists (>1 pane) before spawning
  local has_session = false
  local sf = io.open(SESSION_FILE, 'r')
  if sf then
    local content = sf:read('*a')
    sf:close()
    local session = json_decode(content)
    if session and session.workspaces then
      local total_panes = 0
      for _, ws in ipairs(session.workspaces) do
        for _, win in ipairs(ws.windows or {}) do
          for _, t in ipairs(win.tabs or {}) do
            total_panes = total_panes + #(t.panes or {})
          end
        end
      end
      has_session = total_panes > 1
    end
  end

  local tab, left, _ = mux.spawn_window { workspace = 'main', args = shell }
  tab:set_title('Work')
  mux.set_active_workspace('main')

  if has_session then
    -- Defer heavy session restore so the GUI client doesn't time out
    wezterm.time.call_after(2, function()
      do_restore_session(shell)  -- stats ignored at startup (no window for toast)
      start_autosave()
    end)
  else
    -- No meaningful session — create default 2-pane layout immediately
    left:split { direction = 'Right', size = 0.5, args = shell }
    start_autosave()
  end
end)

-- ============================================================
-- GUI STARTUP — maximize window on open
-- ============================================================
wezterm.on('gui-startup', function()
  local ok, wins = pcall(mux.all_windows)
  if ok and wins then
    for _, win in ipairs(wins) do
      pcall(function()
        local gwin = win:gui_window()
        if gwin then gwin:maximize() end
      end)
    end
  end
  local ok2, names = pcall(mux.get_workspace_names)
  if ok2 and names then
    for _, name in ipairs(names) do
      if name ~= 'default' then
        mux.set_active_workspace(name)
        return
      end
    end
  end
end)

-- ============================================================
-- LAUNCH MENU  (LEADER+s → fuzzy launcher)
-- ============================================================
config.launch_menu = {
  { label='WSL bash',         args={ 'wsl.exe' } },
  { label='PowerShell 7',     args={ 'pwsh.exe', '-NoLogo'                             } },
  { label='PowerShell 5',     args={ 'powershell.exe', '-NoLogo'                       } },
  { label='CMD',              args={ 'cmd.exe'                                          } },
  { label='Git Bash',         args={ 'C:/Program Files/Git/bin/bash.exe', '--login'    } },
}

-- ============================================================
-- MISC
-- ============================================================
-- ── Performance ────────────────────────────────────────────────
config.max_fps                                  = 60    -- cap render rate; prevents GPU thrash
config.animation_fps                            = 10    -- cursor blink / scroll animations
config.status_update_interval                   = 1000  -- ms; keep at 1s for Leader WAIT badge visibility (leader timeout = 2s)
config.prefer_egl                               = true  -- prefer EGL over WGL; more stable on Intel integrated graphics

-- Enhancement 11: Inactive pane dimming (subtle desaturation + brightness reduction)
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }

config.automatically_reload_config              = true
config.exit_behavior                            = 'CloseOnCleanExit'
config.exit_behavior_messaging                  = 'Verbose'
config.selection_word_boundary                  = ' \t\n{}[]()"\''
config.enable_kitty_keyboard                    = false  -- true breaks leader key on Windows
config.skip_close_confirmation_for_processes_named = {
  'powershell.exe', 'pwsh.exe', 'cmd.exe',
  'bash.exe', 'bash', 'zsh', 'fish', 'nu.exe', 'wsl.exe',
}
config.adjust_window_size_when_changing_font_size = false

return config

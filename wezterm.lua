-- ============================================================
--  WezTerm — Full-Featured Config
--  Theme     : Neon Dark (custom)
--  Font      : FiraCode Nerd Font (ligatures on)
--  Shell     : PowerShell 7 (PS5 fallback)
--  Agents    : 7-pane Claude Code workspace on startup
--  Work tab  : 2-pane side-by-side
--  Leader    : CTRL+B  (tmux default)
--  Mux       : built-in unix domain (wezterm connect mux)
--  Sessions  : tmux-resurrect/continuum style save & restore
--              LEADER+Ctrl+S = save   LEADER+Ctrl+R = restore
--              LEADER+Ctrl+N = save named session
--              LEADER+Ctrl+L = list & restore named session
--              LEADER+Ctrl+D = delete named session
--              Auto-saves every 15 min, auto-restores on start
--  Layouts   : LEADER+A        = 7-pane agent grid
--              LEADER+Shift+2  = 2-pane side-by-side
--              LEADER+Shift+3  = 3-pane code layout
--  Broadcast : LEADER+Ctrl+X  = send text to all panes
--  Status    : zoom indicator, git branch, workspace, battery
-- ============================================================

local wezterm = require 'wezterm'
local act     = wezterm.action
local mux     = wezterm.mux

local config  = wezterm.config_builder()

-- Per-window state (keyed by window_id)
local sync_windows  = {}  -- reserved for future sync-mode extensions
local git_branch_cache = {} -- cwd -> { branch, expires }

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

config.window_decorations = 'TITLE | RESIZE'
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
-- BUILT-IN MULTIPLEXER  (like tmux — persists sessions)
--   Attach:  wezterm connect mux
-- ============================================================
config.unix_domains = {
  { name = 'mux' },
}
config.default_gui_startup_args = { 'connect', 'mux' }

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
        items[#items+1] = '"' .. tostring(k) .. '":' .. json_encode(val)
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
        local esc = { ['"']='"', ['\\']='\\', ['/']='/',  n='\n', r='\r', t='\t', b='\b', f='\f' }
        buf[#buf+1] = esc[c] or c
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
        os.rename(dest_file, prev_file)
      end
    end
    os.rename(tmp_file, dest_file)
  end)

  if ok_write and is_main then last_save_time = os.time() end
  return ok_write
end

-- ── Restore panes inside one tab ─────────────────────────────
local function restore_panes(first_pane, panes_data, shell)
  if not panes_data or #panes_data == 0 then return end

  local p1 = panes_data[1]
  if p1 and p1.cwd and #p1.cwd > 0 then
    first_pane:send_text('cd "' .. p1.cwd .. '"\r')
  end

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
      if #cwd > 0 then new_pane:send_text('cd "' .. cwd .. '"\r') end
      prev_pane = new_pane
    end
  end
end

-- ── Restore full session from save file ──────────────────────
local function do_restore_session(shell, file_path)
  local f = io.open(file_path or SESSION_FILE, 'r')
  if not f then return false end
  local content = f:read('*a')
  f:close()

  local session = json_decode(content)
  if not (session and session.workspaces and #session.workspaces > 0) then
    return false
  end

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
    if #first_cwd > 0 then spawn_args.cwd = first_cwd end

    local ok_spawn, tab, first_pane, window = pcall(function()
      return mux.spawn_window(spawn_args)
    end)
    if not ok_spawn then goto next_ws end

    tab:set_title(first_tab.title or ws.name)
    restore_panes(first_pane, first_tab.panes, shell)

    for j = 2, #win_data.tabs do
      local tab_data = win_data.tabs[j]
      local tab_cwd  = ''
      if tab_data.panes and tab_data.panes[1] then
        tab_cwd = tab_data.panes[1].cwd or ''
      end

      local tab_args = { args = shell }
      if #tab_cwd > 0 then tab_args.cwd = tab_cwd end

      local ok_t, new_tab, new_pane = pcall(function()
        return window:spawn_tab(tab_args)
      end)
      if ok_t and new_tab then
        new_tab:set_title(tab_data.title or '')
        restore_panes(new_pane, tab_data.panes, shell)
      end
    end

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

  return any_restored
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
-- GIT BRANCH HELPER  (Enhancement 5)
-- Cached for 10 seconds per directory to avoid spawning git
-- on every status-bar repaint (~1 s interval).
-- ============================================================
local function get_git_branch(cwd)
  if not cwd or #cwd == 0 then return nil end
  local now    = os.time()
  local cached = git_branch_cache[cwd]
  if cached and cached.expires > now then return cached.branch end

  local ok, success, stdout = pcall(wezterm.run_child_process, {
    'git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD',
  })
  local branch = nil
  if ok and success and stdout then
    local b = stdout:gsub('%s+$', '')
    if #b > 0 and b ~= 'HEAD' then branch = b end
  end

  git_branch_cache[cwd] = { branch = branch, expires = now + 10 }
  return branch
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

-- ============================================================
-- KEY BINDINGS  (all tmux-equivalent + new enhancements)
-- ============================================================
config.keys = {

  -- ── PANE SPLITTING ─────────────────────────────────────────
  { key='|', mods='LEADER|SHIFT', action=act.SplitHorizontal { domain='CurrentPaneDomain' } },
  { key='%', mods='LEADER|SHIFT', action=act.SplitHorizontal { domain='CurrentPaneDomain' } },
  { key='-', mods='LEADER',       action=act.SplitVertical   { domain='CurrentPaneDomain' } },
  { key='"', mods='LEADER|SHIFT', action=act.SplitVertical   { domain='CurrentPaneDomain' } },

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
  { key='{', mods='LEADER|SHIFT', action=act.RotatePanes 'CounterClockwise' },
  { key='}', mods='LEADER|SHIFT', action=act.RotatePanes 'Clockwise' },
  { key='o', mods='LEADER', action=act.PaneSelect },
  { key='q', mods='LEADER', action=act.PaneSelect { mode='SwapWithActiveKeepFocus' } },

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
  { key='W', mods='LEADER', action=act.PromptInputLine {
      description = 'New workspace name:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and #line > 0 then
          window:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
  }},

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
      local ok = do_restore_session(shell)
      pcall(function()
        window:toast_notification(
          'WezTerm Sessions',
          ok and 'Session restored  ' or 'No session file found',
          nil, 3000
        )
      end)
  end)},

  -- LEADER + Ctrl+B  →  restore from previous backup (prev.json)
  { key='b', mods='LEADER|CTRL', action=wezterm.action_callback(function(window, _)
      local shell    = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
      local prev_file = SESSION_DIR .. '/prev.json'
      local ok = do_restore_session(shell, prev_file)
      pcall(function()
        window:toast_notification(
          'WezTerm Sessions',
          ok and 'Backup session restored  ' or 'No backup session found',
          nil, 3000
        )
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
            local ok    = do_restore_session(shell, path)
            pcall(function()
              w:toast_notification(
                'WezTerm Sessions',
                ok and ('Restored "' .. id .. '"') or 'Restore failed',
                nil, 3000
              )
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

  -- ── DETACH  (tmux LEADER+d) ─────────────────────────────────
  { key='d', mods='LEADER', action=act.QuitApplication },

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

  -- ── MISC ─────────────────────────────────────────────────────
  { key='r', mods='LEADER',     action=act.ReloadConfiguration },
  { key='?', mods='LEADER|SHIFT', action=act.ShowLauncherArgs { flags='FUZZY|KEY_ASSIGNMENTS' } },
  { key='N', mods='CTRL|SHIFT', action=act.SpawnWindow },
  { key='T', mods='CTRL|SHIFT', action=act.ShowTabNavigator },
  { key='k', mods='CTRL|SHIFT', action=act.Multiple {
      act.ClearScrollback 'ScrollbackAndViewport',
      act.SendKey { key='l', mods='CTRL' },
  }},
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
-- STATUS BAR  (leader | zoom | saved | workspace | panes | process | git | battery | clock)
-- Enhancement 2: zoom indicator
-- Enhancement 5: git branch
-- ============================================================
wezterm.on('update-status', function(window, pane)
  local parts = {}

  -- Leader active indicator
  if window:leader_is_active() then
    parts[#parts+1] = wezterm.format {
      { Background = { Color = neon.magenta } },
      { Foreground = { Color = neon.black   } },
      { Attribute  = { Intensity = 'Bold'   } },
      { Text = '  WAIT  ' },
    }
  end

  -- Enhancement 2: Zoom indicator (visible when a pane is zoomed)
  local ok_pi, panes_info = pcall(function() return window:active_tab():panes_with_info() end)
  if ok_pi and panes_info then
    for _, pinfo in ipairs(panes_info) do
      if pinfo.is_active and pinfo.is_zoomed then
        parts[#parts+1] = wezterm.format {
          { Background = { Color = neon.yellow } },
          { Foreground = { Color = neon.black  } },
          { Attribute  = { Intensity = 'Bold'  } },
          { Text = '  ZOOM  ' },
        }
        break
      end
    end
  end

  -- Session saved indicator (visible for 30 s after save)
  if last_save_time and (os.time() - last_save_time) < 30 then
    parts[#parts+1] = wezterm.format {
      { Background = { Color = neon.green } },
      { Foreground = { Color = neon.black } },
      { Attribute  = { Intensity = 'Bold' } },
      { Text = '  SAVED  ' },
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

  -- Pane count for active tab
  local ok_tab, active_tab = pcall(function() return window:active_tab() end)
  if ok_tab and active_tab then
    local ok_panes, tab_panes = pcall(function() return active_tab:panes() end)
    if ok_panes and tab_panes and #tab_panes > 0 then
      parts[#parts+1] = wezterm.format {
        { Background = { Color = neon.bg_panel } },
        { Foreground = { Color = neon.yellow   } },
        { Text = '  ' .. #tab_panes .. 'p ' },
      }
    end
  end

  -- Active process
  local ok_proc, proc = pcall(function() return pane:get_foreground_process_name() end)
  if not ok_proc then proc = '' end
  proc = proc or ''
  if proc ~= '' then
    proc = proc:match('([^/\\]+)$') or proc
    parts[#parts+1] = wezterm.format {
      { Background = { Color = neon.bg_panel } },
      { Foreground = { Color = neon.purple   } },
      { Text = '  ' .. proc .. ' ' },
    }
  end

  -- Enhancement 5: Git branch (cached 10 s per cwd)
  local ok_cwd, cwd_obj = pcall(function() return pane:get_current_working_dir() end)
  if ok_cwd and cwd_obj then
    local cwd_path = normalize_cwd(cwd_obj)
    local branch   = get_git_branch(cwd_path)
    if branch then
      parts[#parts+1] = wezterm.format {
        { Background = { Color = neon.bg_panel } },
        { Foreground = { Color = neon.yellow   } },
        { Text = '   ' .. branch .. ' ' },
      }
    end
  end

  -- Battery
  local ok, bats = pcall(wezterm.battery_info)
  if ok and bats and #bats > 0 then
    for _, b in ipairs(bats) do
      local pct  = math.floor(b.state_of_charge * 100)
      local col  = pct > 30 and neon.green or neon.red
      local icon = b.state == 'Charging'
                 and wezterm.nerdfonts.md_battery_charging
                 or  wezterm.nerdfonts.md_battery_high
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
-- CONFIG RELOAD TOAST  (Enhancement 4)
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
wezterm.on('mux-startup', function()
  local shell = pwsh and { pwsh, '-NoLogo' } or { 'powershell.exe', '-NoLogo' }

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

  local restored = do_restore_session(shell)

  if not restored then
    local tab, left, _ = mux.spawn_window { workspace = 'main', args = shell }
    tab:set_title('Work')
    left:split { direction = 'Right', size = 0.5, args = shell }
    mux.set_active_workspace('main')
  end

  start_autosave()
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
config.automatically_reload_config              = true
config.check_for_updates                        = true
config.check_for_updates_interval_seconds       = 86400
config.show_update_window                       = false
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

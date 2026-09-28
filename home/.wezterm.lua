-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action
-- This will hold the configuration.
local config = wezterm.config_builder()

-- ============================================================
-- STATUS BAR: leader + active key-table indicator
-- Shows a pill on the right side of the tab bar:
--   - blue pill with the key-table name, when inside a named
--     key table (e.g. resize_pane below)
--   - green "LEADER" pill, when the leader chord is mid-press
-- Both are independent checks, so this scales automatically
-- as you add more key_tables later -- no need to touch this
-- function again.
-- ============================================================
wezterm.on('update-right-status', function(window, pane)
  local segments = {}

  local key_table = window:active_key_table()
  if key_table == 'resize_pane' then
    table.insert(segments, {
      bg = '#214969',
      fg = '#0FC5ED',
      text = '  ● RESIZE  ',
    })
  elseif key_table then
    -- fallback for any other key table you add later
    table.insert(segments, {
      bg = '#214969',
      fg = '#CBE0F0',
      text = '  ' .. key_table:upper() .. '  ',
    })
  end

  if window:leader_is_active() then
    table.insert(segments, {
      bg = '#214969',
      fg = '#47FF9C',
      text = '  ● LEADER  ',
    })
  end

  local elements = {}
  for _, seg in ipairs(segments) do
    table.insert(elements, { Background = { Color = seg.bg } })
    table.insert(elements, { Foreground = { Color = seg.fg } })
    table.insert(elements, { Text = seg.text })
  end

  window:set_right_status(wezterm.format(elements))
end)

-- ============================================================
-- MUX / SESSIONS
-- Defines a local unix-socket domain named "unix" (arbitrary
-- name -- just how you refer to it elsewhere). Launching
-- wezterm auto-starts (or reconnects to) the mux server and
-- opens the first pane inside that domain, so every window is
-- "durable" by default: closing a window just detaches, the
-- server + running processes survive. Only a full quit/kill of
-- wezterm-mux-server, or a machine reboot, actually loses state.
-- ============================================================
config.unix_domains = {
  { name = 'unix' },
}
config.default_gui_startup_args = { 'connect', 'unix' }

-- This is where you actually apply your config choices.
-- For example, changing the initial geometry for new windows:
-- config.initial_cols = 120
-- config.initial_rows = 28

-- ============================================================
-- COLORS (base palette)
-- ============================================================
config.colors = {
  foreground = "#CBE0F0",
  background = "#011423",
  cursor_bg = "#47FF9C",
  cursor_border = "#47FF9C",
  cursor_fg = "#011423",
  selection_bg = "#033259",
  selection_fg = "#CBE0F0",
  ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
  brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
}

-- or, changing the font size and color scheme.
-- config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font = wezterm.font('MesloLGS Nerd Font Mono')
-- config.font_size = platform.is_mac and 12 or 9.75
config.font_size = 14
config.color_scheme = 'AdventureTime'

-- show tabs
config.enable_tab_bar = true

-- ============================================================
-- TAB BAR STYLING (retro-style colors, works alongside fancy bar
-- on current wezterm versions)
-- ============================================================
config.colors.tab_bar = {
  background = 'none',
  active_tab = {
    bg_color = '#214969',
    fg_color = '#CBE0F0',
  },
  inactive_tab = {
    bg_color = 'none',
    fg_color = '#5C7A99',
  },
  inactive_tab_hover = {
    bg_color = '#033259',
    fg_color = '#CBE0F0',
  },
}

-- fancy window / titlebar transparency
-- NOTE: 'none' must be a quoted string, not a bare identifier --
-- unquoted "none" is read as an undefined Lua variable (nil) and
-- silently does nothing.
config.window_frame = {
  active_titlebar_bg = 'none',
  inactive_titlebar_bg = 'none',
}

-- enable kitty graphics protocol (images in-terminal)
config.enable_kitty_graphics = true

-- hide the window buttons, background opacity + blur
config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.8
config.macos_window_background_blur = 10

-- ============================================================
-- LEADER KEY
-- Ctrl-a instead of default Ctrl-b (tmux-style), chosen
-- deliberately over Ctrl-Space since that's reserved for nvim.
-- NOTE: if you ever run tmux *inside* wezterm and tmux's own
-- prefix is also Ctrl-a, wezterm's leader intercepts the
-- keypress first -- the inner tmux session never sees it.
-- Keep tmux's prefix different (or don't stack both layers in
-- the same window) if that matters to you.
-- ============================================================
config.leader = { key = "b", mods = "CTRL" }

-- ============================================================
-- KEY TABLES
-- A key table is a temporary keymap layer -- like a "mode" --
-- entered via ActivateKeyTable and exited via PopKeyTable.
-- Useful for anything you'll press repeatedly without wanting
-- to re-hit the leader every time (resizing, later: copy-mode
-- tweaks, etc). The active table's name automatically shows in
-- the status bar via the update-right-status handler above --
-- no further wiring needed when you add more tables.
-- ============================================================
config.key_tables = {
  resize_pane = {
    { key = 'h', action = act.AdjustPaneSize { 'Left', 5 } },
    { key = 'j', action = act.AdjustPaneSize { 'Down', 5 } },
    { key = 'k', action = act.AdjustPaneSize { 'Up', 5 } },
    { key = 'l', action = act.AdjustPaneSize { 'Right', 5 } },
    -- exit the mode back to normal
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'q', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },
  },
}

-- ============================================================
-- KEY BINDINGS
-- ============================================================
config.keys = {
  -- reconnect / detach from the mux domain
  { key = 'D', mods = 'CTRL|SHIFT', action = act.DetachDomain 'CurrentPaneDomain' },
  { key = 'U', mods = 'CTRL|SHIFT', action = act.AttachDomain 'unix' },

  -- switch workspace (tmux "session" equivalent) --
  -- prompts for a name, creates it if it doesn't exist yet
  { key = 'S', mods = 'CTRL|SHIFT', action = act.SwitchToWorkspace },

  -- pane splits -- named for the divider line's direction, which
  -- is the OPPOSITE of tmux's %/" convention. | = side-by-side,
  -- _ = stacked. No SHIFT in mods: wezterm matches the produced
  -- character, and | and _ already require shift on the keyboard.
  { key = '|', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } }, -- side-by-side
  { key = '_', mods = 'LEADER', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } }, -- stacked

  -- vim-style pane navigation (spatial, not creation-order based)
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- enter resize-pane mode: leader, then r
  -- one_shot = false lets you tap h/j/k/l repeatedly without
  -- re-pressing leader each time; auto-exits after 2s idle,
  -- or press Escape/q/Enter to leave immediately.
  { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable {
      name = 'resize_pane',
      one_shot = false,
      timeout_milliseconds = 2000,
    }
  },

  -- pick a pane by number within current tab (tmux prefix+q equivalent)
  { key = 'q', mods = 'LEADER', action = act.PaneSelect { mode = 'Activate' } },
}

-- ============================================================
-- wez-tmux PLUGIN
-- CAUTION: verify this is actually installed --
--   git clone https://github.com/sei40kr/wez-tmux.git \
--     "$HOME/.config/wezterm/plugins/wez-tmux"
-- If it's not cloned into that path, this require() will error
-- and your whole config will fail to load.
--
-- ALSO CAUTION: this plugin applies AFTER config.keys above, and
-- it ships its own pane/tab/session bindings. It may silently
-- override your custom |/_ splits and vim hjkl nav with its own
-- defaults. Test both sets of bindings after reload -- if your
-- custom ones stop responding, this is why.
-- ============================================================
require("plugins.wez-tmux.plugin").apply_to_config(config, {
    -- Optional: Customize tab index base (0-based or 1-based)
    -- tab_and_split_indices_are_zero_based = true
})

-- append the generated 0-9 tab-jump bindings
for i = 0, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = act.ActivateTab(i),
  })
end

-- bottom bar
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.tab_and_split_indices_are_zero_based = true

-- Finally, return the configuration to wezterm:
return config
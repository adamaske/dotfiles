local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

local SOLID_LEFT_ARROW = utf8.char(0xe0ba)
local SOLID_LEFT_MOST  = utf8.char(0x2588)
local SOLID_RIGHT_ARROW = utf8.char(0xe0bc)

local ADMIN_ICON   = utf8.char(0xf49c)
local CMD_ICON     = utf8.char(0xe62a)
local PS_ICON      = utf8.char(0xe70f)
local VIM_ICON     = utf8.char(0xf15c)
local PAGER_ICON   = utf8.char(0xf718)
local FUZZY_ICON   = utf8.char(0xf0b0)
local HOURGLASS_ICON = utf8.char(0xf252)
local SUNGLASS_ICON  = utf8.char(0xf9df)
local PYTHON_ICON  = utf8.char(0xf820)
local NODE_ICON    = utf8.char(0xe74e)
local LAMBDA_ICON  = utf8.char(0xfb26)

local SUP_IDX = {"¹","²","³","⁴","⁵","⁶","⁷","⁸","⁹","¹⁰",
                 "¹¹","¹²","¹³","¹⁴","¹⁵","¹⁶","¹⁷","¹⁸","¹⁹","²⁰"}
local SUB_IDX = {"₁","₂","₃","₄","₅","₆","₇","₈","₉","₁₀",
                 "₁₁","₁₂","₁₃","₁₄","₁₅","₁₆","₁₇","₁₈","₁₉","₂₀"}

-- ─── Shell ──────────────────────────────────────────────────────────────────
config.default_prog = { "pwsh.exe", "-NoLogo" } 

-- ─── Appearance ─────────────────────────────────────────────────────────────
config.color_scheme = "citruszest"
config.font = wezterm.font_with_fallback({ "JetBrainsMono Nerd Font", "JetBrainsMono NF", "Symbols Nerd Font Mono", "Consolas" })
config.font_size = 14.0
config.line_height = 1

config.front_end = "OpenGL"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8}
config.window_decorations = "RESIZE" 
config.window_background_opacity = 0.9
config.win32_system_backdrop = "Tabbed"
config.initial_cols = 256 
config.initial_rows = 64 

-- Clean up stale GUI sockets from crashed/closed wezterm processes (mirrors Arch)
wezterm.on("gui-startup", function()
  local sock_dir = wezterm.home_dir .. "\\.local\\share\\wezterm"
  for _, sock in ipairs(wezterm.glob(sock_dir .. "\\gui-sock-*")) do
    local pid = sock:match("gui%-sock%-(%d+)$")
    if pid then
      local _, stdout, _ = wezterm.run_child_process({ "tasklist", "/FI", "PID eq " .. pid, "/FO", "CSV", "/NH" })
      if not stdout:find(pid) then
        os.remove(sock)
      end
    end
  end
end)

wezterm.on("gui-startup", function()
  local sock_dir = wezterm.home_dir .. "\\.local\\share\\wezterm"
  for _, sock in ipairs(wezterm.glob(sock_dir .. "\\gui-sock-*")) do
    local pid = sock:match("gui%-sock%-(%d+)$")
    if pid then
      local _, stdout, _ = wezterm.run_child_process({ "tasklist", "/FI", "PID eq " .. pid, "/FO", "CSV", "/NH" })
      if not stdout:find(pid) then
        os.remove(sock)
      end
    end
  end
end)

wezterm.on("window-focus-changed", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = window:is_focused() and 0.3 or 0.3
  window:set_config_overrides(overrides)
end)

-- ─── Tabs ───────────────────────────────────────────────────────────────────
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 60
config.colors = {
  tab_bar = {
    background = "#121212",
    new_tab       = { bg_color = "#121212", fg_color = "#FCE8C3", intensity = "Bold" },
    new_tab_hover = { bg_color = "#121212", fg_color = "#FBB829", intensity = "Bold" },
    active_tab    = { bg_color = "#121212", fg_color = "#FCE8C3" },
  },
}

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local edge_background = "#121212"
  local background = "#4E4E4E"
  local foreground = "#1C1B19"
  local dim_foreground = "#3A3A3A"

  if tab.is_active then
    background = "#FBB829"
    foreground = "#1C1B19"
  elseif hover then
    background = "#FF8700"
    foreground = "#1C1B19"
  end

  local edge_foreground = background
  local process_name = tab.active_pane.foreground_process_name
  local pane_title = tab.active_pane.title
  local exec_name = basename(process_name):gsub("%.exe$", "")
  local title_with_icon

  if exec_name == "pwsh" then
    title_with_icon = PS_ICON .. "  PS"
  elseif exec_name == "cmd" then
    title_with_icon = CMD_ICON .. "  CMD"
  elseif exec_name == "nvim" then
    title_with_icon = VIM_ICON .. pane_title:gsub("^(%S+)%s+(%d+/%d+) %- nvim", "  %2 %1")
  elseif exec_name == "bat" or exec_name == "less" or exec_name == "moar" then
    title_with_icon = PAGER_ICON .. "  " .. exec_name:upper()
  elseif exec_name == "fzf" or exec_name == "peco" then
    title_with_icon = FUZZY_ICON .. "  " .. exec_name:upper()
  elseif exec_name == "btm" or exec_name == "ntop" then
    title_with_icon = SUNGLASS_ICON .. "  " .. exec_name:upper()
  elseif exec_name == "python" then
    title_with_icon = PYTHON_ICON .. "  " .. exec_name
  elseif exec_name == "node" then
    title_with_icon = NODE_ICON .. "  " .. exec_name:upper()
  elseif exec_name == "bb" or exec_name == "janet" then
    title_with_icon = LAMBDA_ICON .. "  " .. exec_name
  else
    title_with_icon = HOURGLASS_ICON .. "  " .. exec_name
  end

  if pane_title:match("^Administrator: ") then
    title_with_icon = title_with_icon .. " " .. ADMIN_ICON
  end

  local left_arrow = tab.tab_index == 0 and SOLID_LEFT_MOST or SOLID_LEFT_ARROW
  local id  = SUB_IDX[tab.tab_index + 1]
  local pid = SUP_IDX[tab.active_pane.pane_index + 1]
  local title = " " .. wezterm.truncate_right(title_with_icon, max_width - 6) .. " "

  return {
    { Attribute = { Intensity = "Bold" } },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = left_arrow },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = id },
    { Text = title },
    { Foreground = { Color = dim_foreground } },
    { Text = pid },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
    { Attribute = { Intensity = "Normal" } },
  }
end)

-- ─── Scrollback ─────────────────────────────────────────────────────────────
config.scrollback_lines = 10000 

-- ─── Leader key: C-b ────────────────────────────────────────────────────────
-- psmux-first setup: psmux owns the C-a prefix (panes/windows/sessions, like Arch
-- tmux), so wezterm's leader lives on C-b and bare Ctrl-hjkl passes straight
-- through to psmux for seamless nvim<->pane navigation.
config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }

-- ─── Key bindings ───────────────────────────────────────────────────────────
config.keys = {

  -- Pass the leader (C-b) through to the shell/psmux when pressed twice
  { key = "b", mods = "LEADER|CTRL", action = act.SendKey({ key = "b", mods = "CTRL" }) },

  -- Splits
  --   C-a \   split right
  --   C-a -   split down
  { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Pane focus  (C-a h/j/k/l  or  C-a arrows)
  { key = "h",          mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j",          mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k",          mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l",          mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "LeftArrow",  mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "DownArrow",  mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "UpArrow",    mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

  -- Pane resize  (C-a C-h/j/k/l, hold Ctrl)
  { key = "h", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Left",  5 }) },
  { key = "j", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Down",  5 }) },
  { key = "k", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Up",    5 }) },
  { key = "l", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Right", 5 }) },

  -- Pane management
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "o", mods = "LEADER", action = act.ActivatePaneDirection("Next") },
  -- Visual pane picker: jump to any pane in the current tab
  { key = "s", mods = "LEADER", action = act.PaneSelect },
  -- Visual pane picker: swap a picked pane with the active one
  { key = "S", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },
  -- Visual pane picker: move selected pane to a new tab
  { key = "m", mods = "LEADER", action = act.PaneSelect({ mode = "MoveToNewTab" }) },

  -- Rotate pane contents within the current tab ([ = CCW, ] = CW)
  { key = "[", mods = "LEADER", action = act.RotatePanes("CounterClockwise") },
  { key = "]", mods = "LEADER", action = act.RotatePanes("Clockwise") },

  -- Tabs
  { key = "c",    mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "n",    mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p",    mods = "LEADER", action = act.ActivateTabRelative(-1) },
  -- Reorder tabs left / right
  { key = "<",    mods = "LEADER", action = act.MoveTabRelative(-1) },
  { key = ">",    mods = "LEADER", action = act.MoveTabRelative(1) },
  { key = "&",    mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
  { key = ",",    mods = "LEADER", action = act.PromptInputLine({
      description = "Rename tab:",
      action = wezterm.action_callback(function(window, _, line)
        if line then window:active_tab():set_title(line) end
      end),
    }),
  },

  -- Jump to tab by number (1–9)
  { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(4) },
  { key = "6", mods = "LEADER", action = act.ActivateTab(5) },
  { key = "7", mods = "LEADER", action = act.ActivateTab(6) },
  { key = "8", mods = "LEADER", action = act.ActivateTab(7) },
  { key = "9", mods = "LEADER", action = act.ActivateTab(8) },

  -- Misc
  { key = "r", mods = "LEADER", action = act.ReloadConfiguration },
}

return config 

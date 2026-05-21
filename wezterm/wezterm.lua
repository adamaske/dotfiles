local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder() 

-- ─── Shell ──────────────────────────────────────────────────────────────────
config.default_prog = { "pwsh.exe", "-NoLogo" } 

-- ─── Appearance ─────────────────────────────────────────────────────────────
config.color_scheme = "citruszest" 
config.font = wezterm.font("JetBrainsMono Nerd Font") 
config.font_size = 14.0 
config.line_height = 1

config.front_end = "OpenGL"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8}
config.window_decorations = "RESIZE" 
config.window_background_opacity = 0.1
config.win32_system_backdrop = "Tabbed"
config.initial_cols = 223 
config.initial_rows = 52 

-- ─── Tabs ───────────────────────────────────────────────────────────────────
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.colors = {
  tab_bar = {
    background = "#000000",
    active_tab        = { bg_color = "#000000", fg_color = "#000000" },
    inactive_tab      = { bg_color = "#000000", fg_color = "#000000" },
    inactive_tab_hover = { bg_color = "#000000", fg_color = "#000000" },
    new_tab           = { bg_color = "#000000", fg_color = "#000000" },
    new_tab_hover     = { bg_color = "#000000", fg_color = "#000000" },
  },
}

local BG = "#000000"
wezterm.on("format-tab-title", function(tab, _, _, _, hover, _)
  local i = tab.tab_index + 1
  if tab.is_active then
    return {
      { Background = { Color = BG } },
      { Foreground = { Color = "#ffffff" } },
      { Text = " |" .. i .. "| " },
    }
  end
  return {
    { Background = { Color = BG } },
    { Foreground = { Color = hover and "#aaaaaa" or "#555555" } },
    { Text = "  " .. i .. "  " },
  }
end)

-- ─── Scrollback ─────────────────────────────────────────────────────────────
config.scrollback_lines = 10000 

-- ─── Leader key: C-a ────────────────────────────────────────────────────────
-- Press Ctrl+A, release, then press the next key within 1 second.
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 } 

-- ─── Key bindings ───────────────────────────────────────────────────────────
config.keys = { 

  -- Pass C-a through to the shell when pressed twice
  { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

  -- Splits
  --   C-a |   split right
  --   C-a -   split down
  { key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
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

  -- Move current pane into an existing tab by number.
  -- Spawns a new shell at the same CWD in the target tab, then closes this pane.
  -- Running processes are NOT preserved.
  {
    key = "t",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local cwd_uri = pane:get_current_working_dir()
      local cwd = nil
      if cwd_uri and cwd_uri.file_path then
        -- Strip the leading slash on Windows paths like /C:/Users/...
        cwd = cwd_uri.file_path:gsub("^/([A-Za-z]:)", "%1")
      end
      local src_pane = pane
      window:perform_action(
        act.PromptInputLine {
          description = "Move pane into tab # (1-based):",
          action = wezterm.action_callback(function(w, _, line)
            if not line then return end
            local n = tonumber(line)
            if not n then return end
            local target_tab
            for _, info in ipairs(w:mux_window():tabs_with_info()) do
              if info.index + 1 == n then target_tab = info.tab; break end
            end
            if not target_tab then return end
            local target_panes = target_tab:panes()
            if #target_panes == 0 then return end
            local args = {
              "wezterm", "cli", "split-pane",
              "--pane-id", tostring(target_panes[#target_panes]:pane_id()),
              "--bottom",
            }
            if cwd then
              table.insert(args, "--cwd")
              table.insert(args, cwd)
            end
            local ok = wezterm.run_child_process(args)
            if ok then
              w:perform_action(act.CloseCurrentPane({ confirm = false }), src_pane)
            end
          end),
        },
        pane
      )
    end),
  },

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

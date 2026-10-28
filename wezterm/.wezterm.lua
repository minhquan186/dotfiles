-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- OS awareness
local function getOS()
  if wezterm.target_triple:find("windows") then
    return "windows"
  elseif wezterm.target_triple:find("linux") then
    return "linux"
  else
    return "macos"
  end
end
local host_os = getOS()

-- Battery status (nil means AC power or no battery)
local function get_battery_status()
  local batteries = wezterm.battery_info()
  if batteries == nil or #batteries == 0 then
    return nil
  end

  local total_charge = 0
  local battery_count = 0
  for _, b in ipairs(batteries) do
    -- Only show while draining; plugged-in batteries may report
    -- Charging, Full, or Unknown ("Not charging" at the charge limit).
    if b.state ~= 'Discharging' and b.state ~= 'Empty' then
      return nil
    end
    if type(b.state_of_charge) == "number" then
      total_charge = total_charge + b.state_of_charge
      battery_count = battery_count + 1
    end
  end

  if battery_count == 0 then
    return "🔋"
  end

  local percentage = math.floor((total_charge / battery_count) * 100 + 0.5)
  return string.format("🔋 %d%%", percentage)
end

-- Cache weather data between status updates.
local weather_cache = {
  data = "",
  next_update = 0,
  interval = 3600,      -- Update every hour
  retry_interval = 300, -- Retry after 5 minutes when offline or on bad response
}

local function get_weather()
  local now = os.time()

  if now < weather_cache.next_update then
    return weather_cache.data
  end

  -- Runs synchronously in update-status, so cap how long it can block the GUI.
  local success, stdout = wezterm.run_child_process({
    "curl", "-s", "-m", "3", "wttr.in/Hanoi?format=%c%t"
  })

  local text = success and stdout:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "") or ""
  -- wttr.in can return error pages with a 200 status; only accept short "<icon> +28°C" output.
  if text:find("°") and #text < 32 then
    weather_cache.data = text
    weather_cache.next_update = now + weather_cache.interval
  else
    weather_cache.next_update = now + weather_cache.retry_interval
  end

  return weather_cache.data
end

-- Folder name for a cwd Url: "~" at home, otherwise the last path component
local function folder_name(cwd_url)
  if not cwd_url then
    return ""
  end
  -- file_path is already percent-decoded (no %20 for spaces)
  local path = cwd_url.file_path:gsub("\\", "/")
  -- On Windows, remove leading slash (/C:/... becomes C:/)
  if host_os == "windows" then
    path = path:gsub("^/", "")
  end
  -- Remove trailing slash, but keep "/" for root
  path = path:gsub("(.)/$", "%1")

  local home_dir = (os.getenv("USERPROFILE") or os.getenv("HOME") or ""):gsub("\\", "/")
  if path == home_dir then
    return "~"
  end
  return path:match("([^/]+)$") or path
end

-- Change shell
if host_os == "windows" then
  config.default_prog = { "pwsh.exe" }
end

-- Changing the initial geometry for new windows
config.initial_cols = 120
config.initial_rows = 28

-- Misc
config.hide_mouse_cursor_when_typing = true
config.scrollback_lines = 3000

-- Font
local emoji_font = host_os == "windows" and "Segoe UI Emoji" or "Noto Color Emoji"
config.font = wezterm.font_with_fallback({
    {
        family = "JetBrainsMono Nerd Font",
        weight = "Regular",
    },
    emoji_font,
})
config.font_size = 14

-- Color scheme
config.color_scheme = "Catppuccin Mocha"

-- Window Config
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.window_background_opacity = 0.75

-- Dim inactive panes
config.inactive_pane_hsb = {
  saturation = 0.25,
  brightness = 0.5,
}

-- Keybinds
-- Set Leader Key as  <C-a>
config.leader = {
  key = "a",
  mods = "CTRL",
  timeout_milliseconds = 1000
}

config.keys = {
  -- Send C-a when pressing C-a twice
  { key = "a", mods = "LEADER|CTRL",  action = act.SendKey { key = "a", mods = "CTRL" } },
  { key = "c", mods = "LEADER",       action = act.ActivateCopyMode },
  -- Pane keybindings
  { key = "-", mods = "LEADER",       action = act.SplitVertical { domain = "CurrentPaneDomain" } },
  -- SHIFT is for when caps lock is on
  { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "h", mods = "LEADER",       action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER",       action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER",       action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER",       action = act.ActivatePaneDirection("Right") },
  { key = "x", mods = "LEADER",       action = act.CloseCurrentPane { confirm = true } },
  -- Rename tab; an empty name goes back to the automatic title
  { key = ",", mods = "LEADER",       action = act.PromptInputLine {
    description = "Rename tab (empty = automatic)",
    action = wezterm.action_callback(function(window, pane, line)
      -- line is nil when cancelled with Esc
      if line then
        window:active_tab():set_title(line)
      end
    end),
  } },
  -- Resize mode: C-a r, then tap h/j/k/l; ends on Esc/Enter, any other key, or 2s idle
  { key = "r", mods = "LEADER",       action = act.ActivateKeyTable {
    name = "resize_pane", one_shot = false, until_unknown = true, timeout_milliseconds = 2000,
  } },
  -- Direct pane bindings (no leader); overrides default ClearScrollback (K) and ShowDebugOverlay (L)
  { key = "h", mods = "CTRL|SHIFT",   action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "CTRL|SHIFT",   action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "CTRL|SHIFT",   action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "CTRL|SHIFT",   action = act.ActivatePaneDirection("Right") },
  { key = "_", mods = "CTRL|SHIFT",   action = act.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "|", mods = "CTRL|SHIFT",   action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  -- Zoom pane on Alt+Enter; fullscreen moves to F11
  { key = "Enter", mods = "ALT",      action = act.TogglePaneZoomState },
  { key = "F11",                      action = act.ToggleFullScreen },
}

config.key_tables = {
  resize_pane = {
    { key = "h",      action = act.AdjustPaneSize { "Left", 2 } },
    { key = "j",      action = act.AdjustPaneSize { "Down", 2 } },
    { key = "k",      action = act.AdjustPaneSize { "Up", 2 } },
    { key = "l",      action = act.AdjustPaneSize { "Right", 2 } },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter",  action = "PopKeyTable" },
  },
}

-- Tab Bar Configuration
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = true
config.switch_to_last_active_tab_when_closing_tab = true
wezterm.on("update-status", function(window, pane)
  -- Placeholder var
  -- Initialize stat variables
  local stat = ""
  local stat_color = "Lime"

  -- Get OS symbol
  if host_os == "windows" then
    stat = wezterm.nerdfonts.dev_windows
    stat_color = "Aqua"
  elseif host_os == "macos" then
    stat = wezterm.nerdfonts.dev_apple
    stat_color = "White"
  else
    stat = wezterm.nerdfonts.dev_linux
    stat_color = "White"
  end

  -- Time
  local time = wezterm.strftime("%H:%M")

  -- Show battery in the weather slot while running on battery power.
  local battery_status = get_battery_status()
  local weather_or_battery = battery_status or get_weather()

  -- Display key table
  if window:active_key_table() then
    stat = window:active_key_table()
    stat_color = "Lime"
  end
  if window:leader_is_active() then
    stat = wezterm.nerdfonts.oct_terminal .. " COMMAND"
    stat_color = "Fuchsia"
  end

  window:set_left_status(wezterm.format({
    { Foreground = { Color = stat_color } },
    { Text = " " },
    { Text = stat},
    { Text = "  " },
  }))

  window:set_right_status(wezterm.format ({
    { Foreground = { Color = "Yellow" } },
    { Text = weather_or_battery },
    "ResetAttributes",
    { Text = " | " },
    { Foreground = { Color = "Silver" } },
    { Text = wezterm.nerdfonts.md_clock_outline .. "  " .. time},
    { Text = "  " },
  }))
end)

-- Tab Title: index + running program (folder name for shells), with zoom and new-output markers
config.tab_max_width = 24
local shells = { bash = true, zsh = true, fish = true, sh = true, nu = true, pwsh = true, powershell = true, cmd = true }

local function tab_label(pane)
  -- Prefer the process name: foreground_process_name is the executable path, which for
  -- versioned installs (e.g. claude/versions/2.1.289) isn't the program name.
  local ok, mux_pane = pcall(wezterm.mux.get_pane, pane.pane_id)
  local info = ok and mux_pane and mux_pane:get_foreground_process_info()
  local process = (info and info.name) or pane.foreground_process_name:match("([^/\\]+)$") or ""
  process = process:gsub("%.exe$", "")

  if process ~= "" and not shells[process] then
    return process
  end
  local folder = folder_name(pane.current_working_dir)
  return folder ~= "" and folder or process
end

-- Shorten from the middle so both the start and end of a name stay visible
local inactive_label_width = 10
local function truncate_middle(s, max)
  if wezterm.column_width(s) <= max then
    return s
  end
  local right = math.ceil((max - 1) / 2)
  local left = max - 1 - right
  return wezterm.truncate_right(s, left) .. "…" .. wezterm.truncate_left(s, right)
end

wezterm.on(
  "format-tab-title",
  function(tab, tabs, panes, config, hover, max_width)
    local pane = tab.active_pane
    -- A name set with Leader+, wins over the automatic label
    local label = tab.tab_title ~= "" and tab.tab_title or tab_label(pane)
    if not tab.is_active then
      label = truncate_middle(label, inactive_label_width)
    end
    local title = (tab.tab_index + 1) .. " " .. label
    if pane.is_zoomed then
      title = title .. " " .. wezterm.nerdfonts.md_fullscreen
    end

    local has_unseen_output = false
    if not tab.is_active then
      for _, p in ipairs(tab.panes or { pane }) do
        if p.has_unseen_output then
          has_unseen_output = true
          break
        end
      end
    end

    -- Truncate the whole label (padding + dot) to max_width. WezTerm calls this twice and
    -- passes the first result's width the second time, so the output must stay the same.
    local dot = has_unseen_output and "● " or ""
    title = wezterm.truncate_right(" " .. title .. " ", max_width - wezterm.column_width(dot))
    return {
      { Text = title },
      { Foreground = { Color = "Orange" } },
      { Text = dot },
    }
  end
)

return config

-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- OS awareness
local function getOS()
  if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    return "windows"
  elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
    return "linux"
  else
    return "macos"
  end
end
local host_os = getOS()

-- Change shell
if host_os == "windows" then
  config.default_prog = { "pwsh.exe" }
end

-- Changing the initial geometry for new windows
config.initial_cols = 120
config.initial_rows = 28

-- Misc
config.default_workspace = "Hello"
config.hide_mouse_cursor_when_typing = true
config.scrollback_lines = 3000

-- Font
local emoji_font = "Segoe UI Emoji"
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
config.window_background_opacity = 0.85

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
  timeout_miliseconds = 1000
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

  -- Weather
  -- Cache for weather data
  local weather_cache = {
    data = "",
    last_update = 0,
    interval = 3600  -- Update every hour
  }

  local function get_weather()
    local now = os.time()

    -- Check if cache is still valid
    if now - weather_cache.last_update < weather_cache.interval then
      return weather_cache.data
    end

    -- Fetch new weather data
    local success, stdout = wezterm.run_child_process({
      "curl", "-s", "wttr.in/Hanoi?format=%c%t"
    })

    if success then
      weather_cache.data = stdout:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
      weather_cache.last_update = now
      return weather_cache.data
    end

    return weather_cache.data  -- Return cached data if fetch fails
  end
  local weather = get_weather()

  -- Display key table
  if window:active_key_table() then
    stat = window:active_key_table()
    stat_color = "Lime"
  end
  if window:leader_is_active() then
    stat = wezterm.nerdfonts.oct_terminal .. " COMMAND"
    stat_color = "Fuchsia"
  end

  -- Get basename
  local basename = function(s)
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  -- Current Working Directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    -- Convert URL object to string
    local cwd_path = tostring(cwd)

    -- Remove file:// prefix
    cwd_path = cwd_path:gsub("^file://", "")

    -- On Windows, remove leading slash (file:///C:/... becomes C:/)
    if host_os == "windows" then
      cwd_path = cwd_path:gsub("^/", "")
    end

    -- Get home directory
    local home_dir = os.getenv("USERPROFILE") or os.getenv("HOME")

    -- Normalize both paths to use forward slashes for comparison
    if home_dir then
      local normalized_cwd = cwd_path:gsub("\\", "/")
      local normalized_home = home_dir:gsub("\\", "/")

      -- Replace home with ~
      if normalized_cwd == normalized_home then
        cwd = "~"
      elseif normalized_cwd:find(normalized_home, 1, true) == 1 then
        cwd = "~" .. normalized_cwd:sub(#normalized_home + 1)
        cwd = basename(cwd)
      else
        cwd = basename(cwd_path)
      end
    else
      cwd = basename(cwd_path)
    end
  else
    cwd = ""
  end

  window:set_left_status(wezterm.format({
    { Foreground = { Color = stat_color } },
    { Text = " " },
    { Text = stat},
    { Text = "  " },
  }))

  window:set_right_status(wezterm.format ({
    { Text = wezterm.nerdfonts.cod_folder_opened .. " " .. cwd},
    { Text = " | " },
    { Foreground = { Color = "Yellow" } },
    { Text = weather },
    { Text = " | " },
    { Foreground = { Color = "Silver" } },
    { Text = wezterm.nerdfonts.md_clock_outline .. "  " .. time},
    { Text = "  " },
  }))
end)

-- Tab Title
wezterm.on(
  "format-tab-title",
  function(tab, tabs, panes, config, hover, max_width)
    local idx = tab.tab_index + 1
    return {{ Text = " " .. idx .. " " }}
  end
)

return config

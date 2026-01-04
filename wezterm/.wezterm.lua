-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font = wezterm.font_with_fallback {
  'Hack Nerd Font Mono',
  'Hack',
  'Fira Code'
}
config.font_size = 11
config.color_scheme = 'GitHub Dark'

config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500
config.animation_fps = 1
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- Finally, return the configuration to wezterm:
return config
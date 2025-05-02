local wezterm = require("wezterm")
local mux = wezterm.mux

wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

local config = {}

config = {
	automatically_reload_config = true,
	enable_tab_bar = false,
	window_close_confirmation = "AlwaysPrompt", --'NeverPrompt' to disable it
	window_decorations = "RESIZE", --disable title but make window resizable
	default_cursor_style = "SteadyBar",
	native_macos_fullscreen_mode = true,
	adjust_window_size_when_changing_font_size = false,
	font = wezterm.font_with_fallback({
		{ family = "Maple Mono NF", harfbuzz_features = { "ss01", "cv03" } },
		{ family = "JetBrainsMono Nerd Font" },
	}),
	font_size = 12,
	line_height = 1.15,
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	window_background_opacity = 0.8,
	macos_window_background_blur = 20,
	mouse_bindings = {
		-- Command + Click to open links
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "CMD",
			action = wezterm.action.OpenLinkAtMouseCursor,
		},
	},
	colors = {
		foreground = "#ffffff", -- Text color
		background = "#000000", -- Background color

		cursor_bg = "#ffffff", -- Cursor color
		cursor_border = "#ffffff", -- Cursor border color
		cursor_fg = "#16181a", -- Cursor text color

		selection_bg = "#3c4048", -- Selection background color
		selection_fg = "#ffffff", -- Selection text color

		-- ANSI colors (basic 16 colors)
		ansi = {
			"#16181a", -- color0 (black)
			"#D9534F", -- color1 (red)
			"#5eff6c", -- color2 (green)
			"#f1ff5e", -- color3 (yellow)
			"#5ea1ff", -- color4 (blue)
			"#bd5eff", -- color5 (magenta)
			"#5ef1ff", -- color6 (cyan)
			"#ffffff", -- color7 (white)
		},

		-- Bright ANSI colors
		brights = {
			"#8D96A0", -- color8  (bright black)
			"#D9534F", -- color9  (bright red)
			"#5eff6c", -- color10 (bright green)
			"#f1ff5e", -- color11 (bright yellow)
			"#5ea1ff", -- color12 (bright blue)
			"#bd5eff", -- color13 (bright magenta)
			"#5ef1ff", -- color14 (bright cyan)
			"#ffffff", -- color15 (bright white)
		},
	},
}

return config

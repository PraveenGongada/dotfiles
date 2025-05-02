---@type ChadrcConfig
---@class ChadrcConfig
local M = {}

------------------------------- base46 ------------------------------------
M.base46 = {
	hl_add = {},
	hl_override = {
		["@comment"] = { italic = true },
		["@keyword.function"] = { italic = true },
		["@keyword.return"] = { italic = true },
		["@keyword"] = { italic = true },
	},
	changed_themes = {},
	integrations = {},
	theme_toggle = { "ayu_dark", "onedark" },
	theme = "ayu_dark", -- default themes
	transparency = true,
}

------------------------------- nvchad_ui modules -----------------------------
M.ui = {
	-- cmp themeing
	cmp = {
		icons_left = true, -- only for non-atom styles!
		abbr_maxwidth = 60,
		style = "default", -- default/flat_light/flat_dark/atom/atom_colored
		format_colors = {
			tailwind = true, -- will work for css lsp too
			icon = "󱓻",
		},
	},

	telescope = { style = "borderless" }, -- borderless / bordered

	statusline = {
		theme = "default", -- default/vscode/vscode_colored/minimal
		-- default/round/block/arrow separators work only for default statusline theme
		-- round and block will work for minimal theme only
		separator_style = "round",
		order = nil,
		modules = nil,
	},

	-- lazyload it when there are 1+ buffers
	tabufline = {
		enabled = true,
		lazyload = true,
		order = { "treeOffset", "buffers", "tabs", "btns" },
		modules = nil,
	},
}

-- lsp
M.lsp = { signature = true }

-- cheatsheet
M.cheatsheet = {
	theme = "grid",                                                  -- grid
	excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" }, -- can add group name or with mode
}

-- colorify
M.colorify = {
	enabled = true,
	mode = "virtual", -- fg, bg, virtual
	virt_text = "󱓻 ",
	highlight = { hex = true, lspvars = true },
}

-- mason
M.mason = { pkgs = {} }

return M

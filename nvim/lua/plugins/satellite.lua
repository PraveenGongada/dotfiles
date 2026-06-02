return {
	"lewis6991/satellite.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "lewis6991/gitsigns.nvim" },
	config = function()
		require("satellite").setup({
			current_only = false,
			winblend = 50,
			zindex = 40,
			width = 2,
			excluded_filetypes = {
				"alpha",
				"NvimTree",
				"TelescopePrompt",
				"lazy",
				"mason",
				"trouble",
				"Trouble",
				"nvcheatsheet",
				"nvdash",
				"leetcode.nvim",
			},
			handlers = {
				cursor = { enable = false },
				search = { enable = false },
				diagnostic = { enable = true },
				gitsigns = {
					enable = true,
					signs = { add = "│", change = "│", delete = "-" },
				},
				marks = { enable = false },
			},
		})
	end,
}

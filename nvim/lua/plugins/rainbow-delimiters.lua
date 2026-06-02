return {
	"HiPhish/rainbow-delimiters.nvim",
	event = { "BufReadPost", "BufNewFile", "VeryLazy" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		local rainbow_delimiters = require("rainbow-delimiters")

		local function set_hl()
			vim.api.nvim_set_hl(0, "RainbowDelimiterGold", { fg = "#FFD700" })
			vim.api.nvim_set_hl(0, "RainbowDelimiterOrchid", { fg = "#DA70D6" })
			vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { fg = "#179FFF" })
		end
		set_hl()

		vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
		vim.api.nvim_create_autocmd("User", { pattern = "NvThemeReload", callback = set_hl })

		require("rainbow-delimiters.setup").setup({
			strategy = {
				[""] = rainbow_delimiters.strategy["global"],
			},
			query = {
				[""] = "rainbow-delimiters",
				javascript = "rainbow-parens",
				typescript = "rainbow-parens",
				tsx = "rainbow-parens",
			},
			highlight = {
				"RainbowDelimiterGold",
				"RainbowDelimiterOrchid",
				"RainbowDelimiterBlue",
			},
		})

		local lib = require("rainbow-delimiters.lib")
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) then
				pcall(lib.attach, buf)
			end
		end
	end,
}

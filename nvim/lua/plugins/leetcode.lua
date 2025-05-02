return {
	"kawre/leetcode.nvim",
	build = ":TSUpdate html",
	cmd = "Leet",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
	},
	opts = function()
		return {
			arg = "leetcode.nvim",
			lang = "java",
			storage = {
				home = vim.fn.stdpath("data") .. "/leetcode",
				cache = vim.fn.stdpath("cache") .. "/leetcode",
			},
			logging = false,
			cache = {
				update_interval = 60 * 60 * 24 * 7,
			},
			console = {
				open_on_runcode = true,
				dir = "row",
				size = {
					width = "90%",
					height = "75%",
				},
				result = {
					size = "60%",
				},
				testcase = {
					virt_text = true,
					size = "40%",
				},
			},
			description = {
				position = "left",
				width = "40%",
				show_stats = true,
			},
			keys = {},
			theme = {},
			image_support = true,
		}
	end,
	config = function(_, opts)
		vim.api.nvim_create_autocmd("BufEnter", {
			pattern = vim.fn.expand("~") .. "/.local/share/nvim/leetcode/*",
			callback = function()
				-- Set indentation settings
				vim.bo.shiftwidth = 4
				vim.bo.tabstop = 4
				vim.bo.softtabstop = 4
				vim.bo.expandtab = true

				-- Disable nvim-cmp
				local cmp = require("cmp")
				cmp.setup.buffer({ enabled = false })
			end,
		})

		require("leetcode").setup(opts)
	end,
}

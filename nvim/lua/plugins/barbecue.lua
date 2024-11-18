return {
	"utilyre/barbecue.nvim",
	name = "barbecue",
	version = "*",
	event = { "BufReadPost", "BufNewFile", "VeryLazy" },
	dependencies = {
		"SmiteshP/nvim-navic",
	},
	opts = {
		theme = {
			normal = { bg = nil, fg = "#43464b" },
		},
		lead_custom_section = function()
			return string.rep(" ", 5)
		end,
		create_autocmd = false,
	},
	config = function(_, opts)
		require("barbecue").setup(opts)

		vim.opt.updatetime = 200

		vim.api.nvim_create_autocmd({
			"WinScrolled",
			"BufWinEnter",
			"CursorHold",
			"InsertLeave",
		}, {
			group = vim.api.nvim_create_augroup("barbecue.updater", {}),
			callback = function()
				require("barbecue.ui").update()
			end,
		})
	end,
}

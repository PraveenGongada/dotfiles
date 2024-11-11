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
			normal = { bg = "#000000", fg = "#43464b" },
		},
	},
	config = function(_, opts)
		require("barbecue").setup(opts)
	end,
}

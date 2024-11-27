return {
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
	},
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
	},
	{	"stevearc/dressing.nvim",
		event = "VeryLazy",
		config = function()
			require("dressing").setup({})
		end,
	},
	{
		"kylechui/nvim-surround",
		event = { "BufReadPost", "BufNewFile" },
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		config = true,
	}
}

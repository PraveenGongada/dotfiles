return {
	"folke/which-key.nvim",
	keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
	cmd = "WhichKey",
	config = function()
		require("which-key").setup()
	end,
}

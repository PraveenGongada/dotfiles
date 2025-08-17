return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile", "VeryLazy" },
	cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
	build = ":TSUpdate",
	dependencies = {
		{ "windwp/nvim-ts-autotag" },
	},
	config = function()
		require("nvim-ts-autotag").setup({})
		local treesitter = require("nvim-treesitter.configs")

		treesitter.setup({
			ensure_installed = {
				"tsx",
				"typescript",
				"toml",
				"json",
				"yaml",
				"go",
				"css",
				"html",
				"lua",
				"vim",
				"vimdoc",
				"bash",
				"java",
				"haskell"
			},
			highlight = {
				enable = true,
				use_languagetree = true,
				additional_vim_regex_highlighting = false,
			},
			-- list of language that will be disabled
			-- disable = { },
			--
			-- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
			disable = function(_, buf)
				local max_filesize = 100 * 1024 -- 100 KB
				local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
				if ok and stats and stats.size > max_filesize then
					return true
				end
			end,

			indent = {
				enable = true,
				disable = {},
			},
		})
	end,
}

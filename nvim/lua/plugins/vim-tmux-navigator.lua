return {
	"christoomey/vim-tmux-navigator",
	keys = {
		{ "<C-h>", "<cmd> TmuxNavigateLeft<CR>", desc = "Window left", silent = true },
		{ "<C-l>", "<cmd> TmuxNavigateRight<CR>", desc = "Window right", silent = true },
		{ "<C-j>", "<cmd> TmuxNavigateDown<CR>", desc = "Window down", silent = true },
		{ "<C-k>", "<cmd> TmuxNavigateUp<CR>", desc = "Window up", silent = true },
	},
}

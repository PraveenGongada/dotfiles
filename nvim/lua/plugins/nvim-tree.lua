return {
	"nvim-tree/nvim-tree.lua",
	cmd = { "NvimTreeToggle" },
	keys = { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
	config = function()
		local nvimtree = require("nvim-tree")

		nvimtree.setup({
			filters = {
				dotfiles = false,
				exclude = {},
			},
			disable_netrw = true,
			diagnostics = {
				enable = true,
			},
			hijack_cursor = true,
			sync_root_with_cwd = true,
			update_focused_file = {
				enable = true,
				update_root = false,
			},
			filesystem_watchers = {
				enable = true,
				ignore_dirs = {
					"node_modules",
				},
			},
			view = {
				adaptive_size = true,
				side = "left",
				width = 30,
				preserve_window_proportions = true,
			},
			git = {
				enable = true,
				ignore = false,
			},
			actions = {
				open_file = {
					resize_window = true,
				},
			},
			renderer = {
				root_folder_label = false,
				highlight_git = true,
				highlight_opened_files = "none",

				indent_markers = {
					enable = true,
				},

				icons = {
					show = {
						file = true,
						folder = true,
						folder_arrow = true,
						git = false,
					},

					glyphs = {
						default = "󰈚",
						symlink = "",
						folder = {
							default = "",
							empty = "",
							empty_open = "",
							open = "",
							symlink = "",
							symlink_open = "",
							arrow_open = "",
							arrow_closed = "",
						},
						git = {
							unstaged = "✗",
							staged = "✓",
							unmerged = "",
							renamed = "➜",
							untracked = "★",
							deleted = "",
							ignored = "◌",
						},
					},
				},
			},
		})

		-- highlights
		vim.cmd([[highlight NvimTreeGitFileNewHL guifg=#73c991]])
		vim.cmd([[highlight NvimTreeGitFileDirtyHL guifg=#e1c08d]])
		vim.cmd([[highlight NvimTreeGitFileMergeHL guifg=#D9534F]])

		vim.cmd([[highlight NvimTreeGitFolderNewHL guifg=#73c991]])
		vim.cmd([[highlight NvimTreeGitFolderDirtyHL guifg=#e1c08d]])
		vim.cmd([[highlight NvimTreeGitFileMergeHL guifg=#D9534F]])

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set(
			"n",
			"<C-n>",
			"<cmd>NvimTreeToggle<CR>",
			{ desc = "Toggle file explorer", silent = true, noremap = true }
		)
		keymap.set(
			"n",
			"<leader>ec",
			"<cmd>NvimTreeCollapse<CR>",
			{ desc = "Collapse file explorer", silent = true, noremap = true }
		)
		keymap.set(
			"n",
			"<leader>er",
			"<cmd>NvimTreeRefresh<CR>",
			{ desc = "Refresh file explorer", silent = true, noremap = true }
		)
	end,
}

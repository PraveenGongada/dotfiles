return {
	"nvim-telescope/telescope.nvim",
	cmd = { "Telescope" },
	event = "VeryLazy",
	dependencies = {
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				dynamic_preview_title = true,
				results_title = false,
				file_ignore_patterns = {
					"node_modules",
					".git/",
					"dist/",
					"build/",
					"vendor/",
					"%.o",
					"%.a",
					"%.out",
					"%.class",
					"%.pdf",
					"%.mkv",
					"%.mp4",
					"%.zip",
					"%.png",
					"%.jpg",
					"%.jpeg",
					"%.DS_Store",
					"%.res",
					"%.mp3",
					"%.ttf",
					"%.otf",
				},
				vimgrep_arguments = {
					"rg",
					"-L",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden",
					"--glob=!.git/",
				},
				prompt_prefix = "   ",
				selection_caret = "  ",
				entry_prefix = "  ",
				initial_mode = "insert",
				selection_strategy = "reset",
				sorting_strategy = "ascending",
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.55,
					},
					vertical = {
						mirror = false,
					},
					width = 0.87,
					height = 0.80,
					preview_cutoff = 120,
				},
				file_sorter = require("telescope.sorters").get_fuzzy_file,
				generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
				path_display = { "truncate" },
				winblend = 0,
				border = {},
				borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
				color_devicons = true,
				set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
				file_previewer = require("telescope.previewers").vim_buffer_cat.new,
				grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
				qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
				-- Developer configurations: Not meant for general override
				buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
				cache_picker = {
					num_pickers = 10,
				},
				mappings = {
					n = {
						["q"] = actions.close, -- close
					},
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
					},
				},
			},

			extensions_list = { "fzf" },
		})

		telescope.load_extension("fzf")
		local builtin = require("telescope.builtin")

		-- Exact word match search
		vim.keymap.set("n", "fw", function()
			builtin.live_grep({
				prompt_title = "Live Grep (Exact Word)",
				additional_args = function()
					return { "--word-regexp" }
				end,
			})
		end, { desc = "Find exact word matches" })

		-- Case sensitive search
		vim.keymap.set("n", "fc", function()
			builtin.live_grep({
				prompt_title = "Live Grep (Case Sensitive)",
				additional_args = function()
					return { "--case-sensitive" }
				end,
			})
		end, { desc = "Find with case sensitivity" })

		vim.keymap.set("n", "fe", function()
			builtin.live_grep({
				prompt_title = "Live Grep (Exact Word + Case Sensitive)",
				additional_args = function()
					return { "--word-regexp", "--case-sensitive", "--fixed-strings" }
				end,
			})
		end, { desc = "Find exact word with case sensitivity" })
	end,
}

-- Run this command if fzf fails on launch
-- cd ~/.local/share/nvim/lazy/telescope-fzf-native.nvim && make && cd -

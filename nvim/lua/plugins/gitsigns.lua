return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPost", "BufNewFile" },
	opts = function()
		return {
			signs = {
				add = { text = "│" },
				change = { text = "│" },
				delete = { text = "󰍵" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "│" },
			},
		}
	end,
	config = function(_, opts)
		require("gitsigns").setup(opts)
		local gitsigns = require("gitsigns")
		local keymap = vim.keymap

		-- Actions
		keymap.set("n", "<leader>gp", function()
			gitsigns.preview_hunk()
		end, { desc = "Preview hunk" })

		keymap.set("n", "<leader>gb", function()
			package.loaded.gitsigns.blame_line()
		end, { desc = "Blame line" })

		keymap.set("n", "<leader>gd", function()
			gitsigns.toggle_deleted()
		end, { desc = "Toggle deleted" })
	end,
}

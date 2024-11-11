return {
	{
		"PraveenGongada/base46",
		lazy = true,
		build = function()
			require("base46").load_all_highlights()
		end,
	},
	{
		"PraveenGongada/ui",
		dependencies = {
			"Nvchad/volt",
		},
		config = function()
			require("nvchad")

			-- mappings
			local keymap = vim.keymap

			-- Tabufline Management
			keymap.set("n", "<tab>", function()
				require("nvchad.tabufline").next()
			end, { desc = "Goto next buffer" })

			keymap.set("n", "<S-tab>", function()
				require("nvchad.tabufline").prev()
			end, { desc = "Goto prev buffer" })

			keymap.set("n", "<leader>x", function()
				require("nvchad.tabufline").close_buffer()
			end, { desc = "Close buffer" })

			-- Theme Management
			keymap.set("n", "<leader>th", function()
				require("nvchad.themes").open({ style = "flat" })
			end, { desc = "Nvchad themes" })

			-- CheatSheet
			keymap.set("n", "<leader>ch", "<cmd> NvCheatsheet <CR>", { desc = "Open CheatSheet" })
		end,
	},
}

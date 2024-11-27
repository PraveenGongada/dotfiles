return {
	"numToStr/Comment.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		require("Comment").setup({
			pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
		})

		-- Mappings
		local keymap = vim.keymap -- for conciseness

		-- Normal Mode Mappings
		keymap.set("n", "<leader>/", function()
			require("Comment.api").toggle.linewise.current()
		end, { desc = "Toggle comment" })

		-- Visual Mode Mappings
		keymap.set(
			"v",
			"<leader>/",
			"<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
			{ desc = "Toggle comment" }
		)
	end,
}

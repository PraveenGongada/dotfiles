return {
	"numToStr/Comment.nvim",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("Comment").setup({})

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

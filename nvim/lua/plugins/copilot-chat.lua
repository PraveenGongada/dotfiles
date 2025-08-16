return {
	"CopilotC-Nvim/CopilotChat.nvim",
	enabled = false,
	branch = "main",
	event = "VeryLazy",
	dependencies = {
		{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
		{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
	},
	build = "make tiktoken", -- Only on MacOS or Linux
	opts = {
		-- See Configuration section for options
	},
	-- See Commands section for default commands if you want to lazy load on them
}

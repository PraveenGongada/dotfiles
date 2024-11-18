return {
	"rcarriga/nvim-notify",
	event = "VeryLazy",
	config = function()
		vim.notify = require("notify")
		require("notify").setup({
			render = "default",
			stages = "fade_in_slide_out",
			timeout = 2000,
			background_colour = "#000000",
		})
	end,
}

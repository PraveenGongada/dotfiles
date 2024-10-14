return {
	"mistricky/codesnap.nvim",
	build = "make",
	cmd = "CodeSnap",
	keys = {
		{
			"<leader>cc",
			function()
				local filetype = vim.bo.filetype
				vim.cmd("CodeSnap " .. filetype)
			end,
			mode = "x",
			desc = "Save selected code snapshot into clipboard",
		},
		{
			"<leader>cs",
			function()
				local filetype = vim.bo.filetype
				vim.cmd("CodeSnapSave " .. filetype)
			end,
			mode = "x",
			desc = "Save selected code snapshot in ~/Pictures",
		},
	},
	opts = function()
		return {
			mac_window_bar = true,
			title = "CodeSnap.nvim",
			code_font_family = "Maple Mono NF",
			watermark_font_family = "Pacifico",
			watermark = "",
			bg_theme = "default", -- summer,sea,grape - bamboo,peach,dusk
			breadcrumbs_separator = "/",
			has_breadcrumbs = false,
			has_line_number = false,
			show_workspace = false,
			min_width = 0,
			bg_x_padding = 122,
			bg_y_padding = 82,
			save_path = os.getenv("XDG_PICTURES_DIR") or (os.getenv("HOME") .. "/Pictures"),
		}
	end,
	config = function(_, opts)
		require("codesnap").setup(opts)
	end,
}

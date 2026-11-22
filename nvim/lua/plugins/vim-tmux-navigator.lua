local herdr_dir = { h = "left", j = "down", k = "up", l = "right" }

local function navigate(key, tmux_cmd)
	return function()
		if vim.env.TMUX or not vim.env.HC_TERMINAL_ID then
			vim.cmd(tmux_cmd)
			return
		end
		local win = vim.api.nvim_get_current_win()
		vim.cmd("wincmd " .. key)
		if win == vim.api.nvim_get_current_win() and vim.fn.executable("herdr-app") == 1 then
			vim.system({ "herdr-app", "do", "pane.go", "--direction", herdr_dir[key] })
		end
	end
end

return {
	"christoomey/vim-tmux-navigator",
	init = function()
		vim.g.tmux_navigator_no_mappings = 1
	end,
	keys = {
		{ "<C-h>", navigate("h", "TmuxNavigateLeft"), desc = "Window left", silent = true },
		{ "<C-l>", navigate("l", "TmuxNavigateRight"), desc = "Window right", silent = true },
		{ "<C-j>", navigate("j", "TmuxNavigateDown"), desc = "Window down", silent = true },
		{ "<C-k>", navigate("k", "TmuxNavigateUp"), desc = "Window up", silent = true },
	},
}

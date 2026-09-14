-- Headless SSH: yank via OSC 52 to the local terminal; paste from nvim's own register
if not vim.env.SSH_TTY or vim.env.DISPLAY or vim.env.WAYLAND_DISPLAY then
	return
end

local osc52 = require("vim.ui.clipboard.osc52")

local function paste()
	return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end

vim.g.clipboard = {
	name = "osc52",
	copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
	paste = { ["+"] = paste, ["*"] = paste },
}

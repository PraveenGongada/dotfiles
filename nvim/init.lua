require("core")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

local function shell_call(args)
	local output = vim.fn.system(args)
	assert(vim.v.shell_error == 0, "External call failed with error code: " .. vim.v.shell_error .. "\n" .. output)
end

local function echo(str)
	vim.cmd("redraw")
	vim.api.nvim_echo({ { str, "Bold" } }, true, {})
end

local function loadPlugins()
	vim.opt.rtp:prepend(lazypath)
	require("lazy").setup("plugins", {
		change_detection = {
			notify = false,
		},
	})
end

local function setup()
	--------- lazy.nvim ---------------
	echo("  Installing lazy.nvim & plugins ...")
	local repo = "https://github.com/folke/lazy.nvim.git"
	shell_call({ "git", "clone", "--depth=1", "--branch=stable", repo, lazypath })

	--------- load plugins ---------------
	loadPlugins()

	--------- install mason packages ---------------
	vim.cmd("MasonToolsInstall")
end

local function loadBase46Cache()
	-- Load all base46 cache files
	for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
		dofile(vim.g.base46_cache .. v)
	end
end

vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"
local hasLazy = vim.loop.fs_stat(lazypath)
if not hasLazy then
	setup()
else
	loadPlugins()
	loadBase46Cache()
end

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

local function protectLockfile()
	local Lock = require("lazy.manage.lock")
	local Config = require("lazy.core.config")
	local update = Lock.update
	Lock.update = function(...)
		local lockfile = Config.options.lockfile
		Lock.load()
		Config.options.lockfile = lockfile .. ".tmp"
		local ok, err = pcall(update, ...)
		Config.options.lockfile = lockfile
		if ok then
			os.rename(lockfile .. ".tmp", lockfile)
			return
		end
		os.remove(lockfile .. ".tmp")
		local broken = {}
		for _, plugin in pairs(Config.plugins) do
			if plugin._.installed and not plugin._.is_local and vim.fn.filereadable(plugin.dir .. "/.git/HEAD") == 0 then
				table.insert(broken, plugin.name)
			end
		end
		vim.notify(
			"lazy-lock.json not updated: " .. tostring(err) .. "\nbroken plugin dirs: " ..
			table.concat(broken, ", ") .. " (delete them and run :Lazy restore)",
			vim.log.levels.WARN
		)
	end
end

local function loadPlugins()
	vim.opt.rtp:prepend(lazypath)
	pcall(protectLockfile)
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
	shell_call({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })

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

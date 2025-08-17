-- Additional performance optimizations for Neovim

-- Disable some builtin vim plugins that we don't need
local disabled_built_ins = {
  "2html_plugin",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "logipat",
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "matchit",
  "tar",
  "tarPlugin",
  "rrhelper",
  "spellfile_plugin",
  "vimball",
  "vimballPlugin",
  "zip",
  "zipPlugin",
  "tutor",
  "rplugin",
  "synmenu",
  "optwin",
  "compiler",
  "bugreport",
}

for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

-- Reduce the number of items in command history
vim.opt.history = 1000

-- Optimize grep command for better performance
if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep --smart-case --follow"
end

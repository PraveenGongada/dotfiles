-- for conciseness
local opt = vim.opt
local g = vim.g

-- General Settings
opt.laststatus = 3            -- Use a global statusline
opt.showmode = false          -- Disable showing the current mode (useful if you're using a statusline plugin)
opt.clipboard = "unnamedplus" -- Use system clipboard for yank, delete, change, and put operations
opt.cursorline = true         -- Highlight the line the cursor is on for better visibility

-- Indentation Settings
opt.expandtab = true   -- Convert tabs to spaces
opt.shiftwidth = 2     -- Use 2 spaces for each step of (auto)indent
opt.smartindent = true -- Auto-indent based on file type and syntax
opt.tabstop = 2        -- Display tabs as 2 spaces
opt.softtabstop = 2    -- Treat a tab as 2 spaces when editing

-- Display Settings
opt.fillchars = { eob = " " } -- Hide `~` characters on empty lines
opt.ignorecase = true         -- Ignore case in search patterns
opt.smartcase = true          -- Override `ignorecase` if the search contains uppercase letters
opt.mouse = "a"               -- Enable mouse in all modes

-- Line Numbers
opt.number = true         -- Show absolute line number on the cursor line
opt.relativenumber = true -- Show relative line numbers for easier navigation
opt.numberwidth = 2       -- Set width of the number column
opt.ruler = false         -- Disable the ruler, as the global statusline can handle this

-- Disable Neovim Intro
opt.shortmess:append("sI") -- Disable the intro message when starting Neovim

-- Backspace Behavior
opt.backspace = "indent,eol,start" -- Allow backspace over indentation, end of line, and insert mode start

-- Split Windows Behavior
opt.signcolumn = "yes" -- Always show the sign column to prevent text shifting
opt.splitbelow = true  -- New horizontal splits will open below the current window
opt.splitright = true  -- New vertical splits will open to the right of the current window

-- Appearance
opt.termguicolors = true -- Enable 24-bit RGB colors for better syntax highlighting and theming
opt.background = "dark"  -- colorschemes that can be light or dark will be made dark

-- Performance
opt.timeoutlen = 300 -- Time in milliseconds to wait for a mapped sequence to complete
opt.undofile = true  -- Enable persistent undo, allowing you to undo changes even after reopening the file
opt.updatetime = 250 -- Time in milliseconds before writing the swap file to disk (used by gitsigns and others)

-- Performance Optimizations
opt.lazyredraw = false -- Keep redrawing for smooth interaction
opt.synmaxcol = 300    -- Increase syntax highlighting column limit
opt.redrawtime = 10000 -- Time in milliseconds for redrawing the display
opt.ttyfast = true     -- Optimize for fast terminal connections
opt.regexpengine = 0   -- Use automatic regexp engine selection

-- Navigation
opt.whichwrap:append("<>[]hl") -- Allow the cursor to move to the next/previous line when using `h`, `l`, or arrow keys

-- Scrolling
opt.scrolloff = 10 -- Keep at least 10 lines visible above and below the cursor during scrolling

-- Disable netrw
g.loaded_netrw = 1       -- Prevent netrw from loading, avoiding conflicts with nvim-tree
g.loaded_netrwPlugin = 1 -- Disable the netrw plugin as well, fully disabling netrw

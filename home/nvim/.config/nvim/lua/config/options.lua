local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 6
opt.mouse = "a"
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 450
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.smartindent = true
opt.clipboard = ""
opt.laststatus = 3

-- Tree-sitter folds (set per buffer in plugins/treesitter.lua) start open.
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Fixed dark appearance, independent of macOS Light/Dark mode.
-- Ghostty and a correctly configured tmux support 24-bit color.
opt.termguicolors = true
opt.background = "dark"

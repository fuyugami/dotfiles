-- Ghostty + tmux + Neovim 0.12.6
-- Keep entry point short; see lua/config/ and lua/plugins/.

-- Must be set before lazy.nvim loads any plugin keymaps.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- mini.files opens directory buffers (`nvim .`); nvim-tree is an on-demand sidebar.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.options")
require("config.autocmds")
require("config.keymaps")
require("config.lazy")
require("config.lsp")
require("config.devtools")

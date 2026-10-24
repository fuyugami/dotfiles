-- lazy.nvim plugin specification
return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- fixed, not "auto"
				transparent_background = false, -- draw an actual dark background
			})
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
}

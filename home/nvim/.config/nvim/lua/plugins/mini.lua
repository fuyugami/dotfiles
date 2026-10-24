-- lazy.nvim plugin specification
return {
	{
		"nvim-mini/mini.nvim",
		version = false,
		lazy = false,
		config = function()
			require("mini.icons").setup({ style = "ascii" })
			require("mini.files").setup()
			require("mini.surround").setup()
			require("mini.statusline").setup({ use_icons = false })
			require("mini.completion").setup() -- small LSP/word completion
		end,
	},
}

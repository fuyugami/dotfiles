-- lazy.nvim plugin specification
-- Renders Markdown inside the buffer (headings, lists, code blocks, tables,
-- callouts); the line under the cursor shows the raw text for editing.
return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
		opts = {
			-- Checkbox and callout completions through mini.completion's LSP source.
			completions = { lsp = { enabled = true } },
		},
		keys = {
			{
				"<leader>mp",
				"<cmd>RenderMarkdown buf_toggle<CR>",
				ft = "markdown",
				desc = "Toggle Markdown rendering",
			},
			{
				"<leader>mP",
				"<cmd>RenderMarkdown preview<CR>",
				ft = "markdown",
				desc = "Rendered Markdown in a side split",
			},
		},
	},
}

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
			pipe_table = {
				-- Rounded box-drawing borders (╭─┬─╮).
				preset = "round",
				-- Draw the top and bottom borders on virtual lines, so tables without
				-- a blank line above or below still get a full frame.
				border_virtual = true,
				-- Rows wider than the window wrap inside their cells (pipe_table.wrap,
				-- on by default). That only happens while 'wrap' is on, so keep it on.
			},
			anti_conceal = {
				-- Keep the table borders drawn when the cursor is on a table row;
				-- only the cell text goes raw for editing.
				ignore = { table_border = true },
			},
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

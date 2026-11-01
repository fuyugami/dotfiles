-- lazy.nvim plugin specification
-- Live browser preview for Markdown (also HTML and AsciiDoc): GitHub-style HTML,
-- Mermaid diagrams, scroll synced with the buffer. The server is plain Lua, so no
-- Node or Deno. In-buffer rendering stays with render-markdown.lua.
return {
	{
		"brianhuster/live-preview.nvim",
		cmd = "LivePreview",
		config = function()
			require("livepreview.config").set({
				picker = "fzf-lua",
			})
		end,
		keys = {
			{
				"<leader>mb",
				"<cmd>LivePreview start<CR>",
				ft = "markdown",
				desc = "Live preview in the browser",
			},
			{
				"<leader>mB",
				"<cmd>LivePreview close<CR>",
				ft = "markdown",
				desc = "Stop the browser preview",
			},
		},
	},
}

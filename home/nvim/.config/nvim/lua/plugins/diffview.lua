return {
	{
		"sindrets/diffview.nvim",

		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewFileHistory",
			"DiffviewFocusFiles",
			"DiffviewToggleFiles",
			"DiffviewRefresh",
		},

		keys = {
			{
				"<leader>gD",
				"<cmd>DiffviewOpen HEAD<CR>",
				desc = "Review all changes since HEAD",
			},
			{
				"<leader>gu",
				"<cmd>DiffviewOpen<CR>",
				desc = "Review unstaged changes",
			},
			{
				"<leader>gS",
				"<cmd>DiffviewOpen --cached<CR>",
				desc = "Review staged changes",
			},
			{
				"<leader>gH",
				"<cmd>DiffviewFileHistory %<CR>",
				desc = "Git history of current file",
			},
			{
				"<leader>gF",
				"<cmd>DiffviewFocusFiles<CR>",
				desc = "Focus Git changed-file panel",
			},
			{
				"<leader>gC",
				"<cmd>DiffviewClose<CR>",
				desc = "Close Git diff view",
			},
		},

		opts = {
			-- Match a minimal, dark Neovim setup
			use_icons = false,
			signs = {
				fold_closed = ">",
				fold_open = "v",
				done = "✓",
			},

			enhanced_diff_hl = true,
			watch_index = true,
			show_help_hints = true,

			view = {
				default = {
					layout = "diff2_horizontal",
					winbar_info = true,
				},
				file_history = {
					layout = "diff2_horizontal",
					winbar_info = true,
				},
				merge_tool = {
					layout = "diff3_horizontal",
					winbar_info = true,
				},
			},

			file_panel = {
				listing_style = "tree",
				tree_options = {
					flatten_dirs = true,
					folder_statuses = "only_folded",
				},
				win_config = {
					position = "left",
					width = 34,
				},
			},

			file_history_panel = {
				win_config = {
					position = "bottom",
					height = 14,
				},
			},

			hooks = {
				diff_buf_read = function()
					-- Soft-wrap long lines at word boundaries (<leader>uw toggles per window)
					vim.opt_local.wrap = true
					vim.opt_local.linebreak = true
					vim.opt_local.list = false
				end,
			},

			-- Keep built-in Diffview navigation
			keymaps = {
				disable_defaults = false,
			},
		},

		config = function(_, opts)
			require("diffview").setup(opts)

			-- Diffview only supports a fixed panel width. Fit the changed-file
			-- panel to its longest line instead, like nvim-tree's view.width:
			-- never narrower than the configured width, never wider than 40%.
			local FilePanel = require("diffview.scene.views.diff.file_panel").FilePanel
			local min_width = opts.file_panel.win_config.width
			local max_ratio = 0.4

			local get_config = FilePanel.get_config
			function FilePanel:get_config()
				local config = get_config(self)
				local sideways = config.position == "left" or config.position == "right"

				if config.type == "split" and sideways and self:buf_loaded() then
					local longest = 0
					for _, line in ipairs(vim.api.nvim_buf_get_lines(self.bufid, 0, -1, false)) do
						longest = math.max(longest, vim.fn.strdisplaywidth(line))
					end

					local max_width = math.floor(vim.o.columns * max_ratio)
					config.width = math.max(min_width, math.min(longest + 2, max_width))
				end

				return config
			end

			-- Re-fit whenever the list changes (open/close folders, new files)
			local redraw = FilePanel.redraw
			function FilePanel:redraw(...)
				redraw(self, ...)
				self:resize()
			end
		end,
	},
}

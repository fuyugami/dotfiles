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
					-- Avoid wrapping code in side-by-side diffs
					vim.opt_local.wrap = false
					vim.opt_local.list = false
				end,
			},

			-- Keep built-in Diffview navigation
			keymaps = {
				disable_defaults = false,
			},
		},
	},
}

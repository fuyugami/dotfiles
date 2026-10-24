return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },

		opts = {
			-- Subtle signs; no Nerd Font required
			signs = {
				add = { text = "┃" },
				change = { text = "┃" },
				delete = { text = "▁" },
				topdelete = { text = "▔" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},

			signs_staged_enable = true,
			current_line_blame = false,
			word_diff = false,
			attach_to_untracked = false,

			preview_config = {
				border = "rounded",
			},

			on_attach = function(bufnr)
				local gs = require("gitsigns")

				local function map(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, {
						buffer = bufnr,
						silent = true,
						desc = desc,
					})
				end

				-- Navigate changed hunks
				map("n", "]h", function()
					gs.nav_hunk("next")
				end, "Next Git hunk")

				map("n", "[h", function()
					gs.nav_hunk("prev")
				end, "Previous Git hunk")

				-- Inspect changes
				map("n", "<leader>gp", gs.preview_hunk, "Preview Git hunk")

				map("n", "<leader>gi", gs.preview_hunk_inline, "Preview hunk inline")

				map("n", "<leader>gd", gs.diffthis, "Diff file against index")

				-- Git blame
				map("n", "<leader>gb", function()
					gs.blame_line({ full = true })
				end, "Git blame line")

				map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle inline Git blame")

				-- Stage / discard hunks
				map("n", "<leader>ghs", gs.stage_hunk, "Stage/unstage Git hunk")

				map("n", "<leader>ghr", gs.reset_hunk, "Discard unstaged Git hunk")

				-- Stage / discard visual selection
				map("x", "<leader>ghs", function()
					gs.stage_hunk({
						vim.fn.line("."),
						vim.fn.line("v"),
					})
				end, "Stage selected Git lines")

				map("x", "<leader>ghr", function()
					gs.reset_hunk({
						vim.fn.line("."),
						vim.fn.line("v"),
					})
				end, "Discard selected Git lines")

				-- Optional word-level diff
				map("n", "<leader>gW", gs.toggle_word_diff, "Toggle Git word diff")
			end,
		},
	},
}

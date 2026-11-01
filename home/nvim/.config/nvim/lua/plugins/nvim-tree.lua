return {
	{
		"nvim-tree/nvim-tree.lua",

		cmd = {
			"NvimTreeToggle",
			"NvimTreeFindFile",
		},

		keys = {
			{
				"<leader>te",
				"<cmd>NvimTreeToggle<CR>",
				desc = "Toggle project tree",
			},
			{
				"<leader>tr",
				"<cmd>NvimTreeFindFile<CR>",
				desc = "Reveal current file in tree",
			},
		},

		opts = {
			sync_root_with_cwd = true,

			update_focused_file = {
				enable = true,
			},

			view = {
				-- Grow to fit the longest visible name, capped so the editor keeps room
				width = {
					min = 36,
					max = "40%",
				},
				side = "left",
			},

			renderer = {
				-- Names still clipped by the cap show in full in a float under the cursor
				full_name = true,
				group_empty = true,
				highlight_git = "icon",

				icons = {
					git_placement = "after",

					-- Keep a clean tree without Nerd Fonts
					show = {
						file = false,
						folder = false,
						folder_arrow = false,
						git = true,
						modified = true,
					},

					glyphs = {
						modified = "*", -- Unsaved buffer

						git = {
							unstaged = "M",
							staged = "✓",
							unmerged = "!",
							renamed = "R",
							untracked = "?",
							deleted = "D",
							ignored = "·",
						},
					},
				},
			},

			-- Git integration
			git = {
				enable = true,
				show_on_dirs = true,
				show_on_open_dirs = true,
				timeout = 400,
			},

			-- Distinguish unsaved edits from Git changes
			modified = {
				enable = true,
				show_on_dirs = true,
			},

			filters = {
				git_ignored = false,
				dotfiles = false,
				git_clean = false,
				custom = {},
			},
		},

		config = function(_, opts)
			require("nvim-tree").setup(opts)
		end,
	},
}

return {
	{
		"nvim-tree/nvim-tree.lua",

		-- Loaded at startup: it opens on launch and handles `nvim <dir>`.
		lazy = false,

		keys = {
			{
				"<leader>e",
				"<cmd>NvimTreeToggle<CR>",
				desc = "Toggle project tree",
			},
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

			-- `nvim <dir>`: show the tree for that folder instead of a directory buffer.
			hijack_directories = {
				enable = true,
				auto_open = true,
			},

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

			-- Text piped in (`cmd | nvim -`) is not a project: no tree.
			local from_stdin = false
			vim.api.nvim_create_autocmd("StdinReadPre", {
				callback = function()
					from_stdin = true
				end,
			})

			-- Open the tree on launch for `nvim` and `nvim <dir>` (the tproj editor
			-- pane), rooted at that folder. Editing files (`nvim foo.py`, git commit
			-- messages) and diff mode start without it.
			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function(data)
					if from_stdin or vim.o.diff or #vim.api.nvim_list_uis() == 0 then
						return
					end
					local api = require("nvim-tree.api")
					if vim.fn.argc() == 0 then
						api.tree.open({ path = vim.fn.getcwd() })
					elseif vim.fn.argc() == 1 and vim.fn.isdirectory(data.file) == 1 then
						vim.cmd.cd(data.file)
						api.tree.open({ path = vim.fn.getcwd() })
					end
				end,
			})
		end,
	},
}

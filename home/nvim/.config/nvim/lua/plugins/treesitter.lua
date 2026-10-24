-- lazy.nvim plugin specification
return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",

		config = function()
			-- The main branch doesn't auto-install parsers. Already-installed
			-- parsers are skipped, so this is a no-op on normal startups.
			require("nvim-treesitter").install({
				"go",
				"gomod",
				"gowork",
				"python",
				"javascript",
				"typescript",
				"tsx",
				"html",
				"css",
				"json",
				"yaml",
				"toml",
				"make",
				"dockerfile",
				"bash",
				"markdown",
				"markdown_inline",
				"lua",
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = {
					-- Go
					"go",
					"gomod",
					"gowork",

					-- Python
					"python",

					-- React / JS / TS
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",

					-- Web / config
					"html",
					"css",
					"json",
					"jsonc",
					"yaml",
					"toml",

					-- DevOps
					"make",
					"dockerfile",
					"sh",

					-- Documentation
					"markdown",

					-- Neovim
					"lua",
				},

				callback = function(args)
					if not pcall(vim.treesitter.start, args.buf) then
						return
					end
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					vim.wo[0][0].foldmethod = "expr"
					vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
				end,
			})
		end,
	},
}

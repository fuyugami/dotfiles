-- lazy.nvim plugin specification
return {
	{
		-- Uses installed formatter executables, not an automatic tool installer.
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = { "n", "x" },
				desc = "Format current file / selection",
			},
		},
		opts = {
			formatters_by_ft = {
				-- Ruff is supplied by the activated Conda env, never by Neovim itself.
				python = { "ruff_organize_imports", "ruff_format" },
				go = { "goimports" }, -- gofmt formatting + automatic import organization
				lua = { "stylua" },
				-- Conform resolves project-local node_modules/.bin/prettier.
				-- Install Prettier through npm in each JS/TS project.
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
			},
			-- Format with installed formatters on save; don't invoke LSP formatters automatically.
			-- Disable per buffer with :lua vim.b.disable_autoformat = true
			-- No warning for repositories that intentionally lack a formatter.
			notify_no_formatters = false,
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 1500, lsp_format = "never" }
			end,
		},
	},
}

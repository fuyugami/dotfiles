local map = vim.keymap.set

-- Focused diagnostics; inspect all diagnostics with :lua vim.diagnostic.setloclist().
vim.diagnostic.config({
	severity_sort = true,
	update_in_insert = false,
	virtual_text = { severity = vim.diagnostic.severity.ERROR },
	float = { border = "rounded" },
})
map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Python environment selection:
-- Start nvim *after* `conda activate <env>` in the project shell.
-- Only then pin Pyright to that environment's interpreter. If no Conda
-- environment is active, let Pyright perform its normal discovery.
local conda_prefix = vim.env.CONDA_PREFIX
if conda_prefix and conda_prefix ~= "" then
	local python_exe = conda_prefix .. "/bin/python"
	if vim.fn.executable(python_exe) == 1 then
		vim.lsp.config("pyright", {
			settings = { python = { pythonPath = python_exe } },
		})
	end
end

-- Ruff provides fast Python diagnostics/code actions from the Conda env;
-- Pyright remains responsible for type analysis, completion, navigation.
if vim.fn.executable("ruff") == 1 then
	vim.lsp.config("ruff", {
		on_attach = function(client)
			client.server_capabilities.hoverProvider = false
		end,
	})
end

-- Teach lua_ls about the Neovim runtime (`vim` global, vim.api types) when
-- editing this config. Other Lua projects with their own .luarc keep theirs.
vim.lsp.config("lua_ls", {
	on_init = function(client)
		local folders = client.workspace_folders
		if folders then
			local path = folders[1].name
			if
				path ~= vim.fn.stdpath("config")
				and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
			then
				return
			end
		end
		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
			runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
			workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
		})
	end,
	settings = { Lua = {} },
})

-- LSP: the server executables are optional; install only what you use.
for _, server in ipairs({
	{ exe = "gopls", id = "gopls" }, -- installed with `go install`
	{ exe = "ruff", id = "ruff" }, -- Conda environment; built-in Ruff server
	{ exe = "pyright-langserver", id = "pyright" },
	{ exe = "typescript-language-server", id = "ts_ls" },
	{ exe = "lua-language-server", id = "lua_ls" },
}) do
	if vim.fn.executable(server.exe) == 1 then
		vim.lsp.enable(server.id) -- Nvim 0.11+, NOT require('lspconfig').setup
	end
end

-- Buffer-local LSP mappings, so non-LSP buffers keep Vim's built-in `gd`.
-- `K` (hover) is set automatically by Neovim when a server attaches.
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local function bmap(mode, lhs, rhs, desc)
			map(mode, lhs, rhs, { buffer = args.buf, desc = desc })
		end
		bmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
		bmap("n", "<leader>lr", vim.lsp.buf.references, "LSP references")
		bmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
		bmap({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
	end,
})

-- Diagnostics can come from non-LSP sources too, so these stay global.
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

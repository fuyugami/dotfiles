-- Read-only diagnostics for tool discovery. Does not install anything.
vim.api.nvim_create_user_command("DevTools", function()
	local names = {
		"go",
		"gopls",
		"goimports",
		"python",
		"ruff",
		"pyright-langserver",
		"node",
		"npm",
		"typescript-language-server",
		"prettier",
		"stylua",
		"rg",
		"fd",
	}
	local lines = { "Executable paths in Neovim's current environment:" }
	for _, name in ipairs(names) do
		local found = vim.fn.exepath(name)
		lines[#lines + 1] = string.format("%-28s %s", name, found ~= "" and found or "(not on PATH)")
	end
	lines[#lines + 1] = "CONDA_DEFAULT_ENV=" .. (vim.env.CONDA_DEFAULT_ENV or "(none)")
	lines[#lines + 1] = "CONDA_PREFIX=" .. (vim.env.CONDA_PREFIX or "(none)")
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Dev tools" })
end, { desc = "Show which developer tools Neovim can see" })

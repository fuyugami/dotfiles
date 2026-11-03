-- 2 spaces for web/config files, 4 for Python by default.
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"jsonc",
		"yaml",
		"html",
		"css",
		"scss",
		"lua",
	},
	callback = function()
		vim.bo.shiftwidth = 2
		vim.bo.tabstop = 2
		vim.bo.softtabstop = 2
	end,
})

-- Go uses tabs by convention. Leave final formatting/import sorting to goimports.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "go",
	callback = function()
		vim.bo.expandtab = false
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 0
	end,
})

-- LaTeX is prose: wrap long lines at word boundaries instead of scrolling sideways.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "tex", "bib" },
	callback = function()
		vim.wo[0][0].wrap = true
		vim.wo[0][0].linebreak = true
		vim.bo.shiftwidth = 2
		vim.bo.tabstop = 2
		vim.bo.softtabstop = 2
	end,
})

-- Notebook scripts (jupytext py:percent, `# %%` cells): ]x / [x jump between cells.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function(args)
		local function jump(flags)
			return function()
				for _ = 1, vim.v.count1 do
					vim.fn.search("^# %%", flags)
				end
			end
		end
		local opts = { buffer = args.buf }
		vim.keymap.set(
			{ "n", "x", "o" },
			"]x",
			jump("W"),
			vim.tbl_extend("force", opts, { desc = "Next notebook cell" })
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"[x",
			jump("bW"),
			vim.tbl_extend("force", opts, { desc = "Previous notebook cell" })
		)
	end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	callback = function()
		if not vim.bo.modified then
			vim.cmd("silent! checktime")
		end
	end,
	desc = "Refresh files edited by coding agents",
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
	callback = function(args)
		vim.notify("Updated from disk: " .. vim.fn.fnamemodify(args.file, ":t"), vim.log.levels.INFO)
	end,
	desc = "Notify after external file changes",
})

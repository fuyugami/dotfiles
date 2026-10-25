-- lazy.nvim plugin specification
-- LaTeX: continuous builds with latexmk, PDF in Skim (macOS) or Zathura (Linux),
-- SyncTeX in both directions. Mappings live under <localleader>l (\l…).
-- texlab (lsp.lua) adds completion, diagnostics and formatting.
return {
	{
		"lervag/vimtex",
		-- VimTeX loads itself for .tex files; lazy-loading it breaks inverse search.
		lazy = false,
		init = function()
			if vim.fn.has("mac") == 1 then
				vim.g.vimtex_view_method = "skim"
				vim.g.vimtex_view_skim_sync = 1 -- jump to the cursor's spot after each build
				vim.g.vimtex_view_skim_activate = 0 -- keep focus in the terminal
				vim.g.vimtex_view_skim_reading_bar = 1
			elseif vim.fn.executable("zathura") == 1 then
				vim.g.vimtex_view_method = "zathura"
			end

			-- Errors open the quickfix list without moving the cursor; warnings don't.
			vim.g.vimtex_quickfix_mode = 2
			vim.g.vimtex_quickfix_open_on_warning = 0
		end,
	},
}

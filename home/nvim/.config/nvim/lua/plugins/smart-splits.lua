-- lazy.nvim plugin specification
return {
	{
		-- <C-h/j/k/l> moves across Neovim splits, then on into tmux panes.
		-- Not lazy-loaded: the tmux backend must tag the pane (@pane-is-vim) at
		-- startup, or tmux swallows <C-h/j/k/l>. Pairs with bindings in ~/.tmux.conf.
		"smart-splits-nvim/smart-splits.nvim",
		version = "^3.0.0",
		lazy = false,
		dependencies = {
			{ "smart-splits-nvim/backend-tmux", main = "smart-splits-backend-tmux", opts = {} },
		},
		opts = {
			mux = { backend = "smart-splits-backend-tmux" },
			-- Keep in step with the tmux bindings (plain select-pane wraps).
			move = { at_edge = "wrap" },
		},
		keys = {
			{
				"<C-h>",
				function()
					require("smart-splits").move_cursor_left()
				end,
				desc = "Focus left split/pane",
			},
			{
				"<C-j>",
				function()
					require("smart-splits").move_cursor_down()
				end,
				desc = "Focus lower split/pane",
			},
			{
				"<C-k>",
				function()
					require("smart-splits").move_cursor_up()
				end,
				desc = "Focus upper split/pane",
			},
			{
				"<C-l>",
				function()
					require("smart-splits").move_cursor_right()
				end,
				desc = "Focus right split/pane",
			},
		},
	},
}

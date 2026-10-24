# Neovim

Plain [lazy.nvim](https://github.com/folke/lazy.nvim) config for Neovim 0.12+ (not
LazyVim), linked to `~/.config/nvim`. Native LSP (`vim.lsp.config` / `vim.lsp.enable`),
tree-sitter `main` branch, Catppuccin Mocha.

## Structure

```
init.lua                  leaders, netrw off, then loads lua/config/*
lua/config/
  options.lua             editor options (numbers, wrap, search, indent, folds, clipboard)
  autocmds.lua            per-filetype indentation (2 spaces web/lua, tabs for Go)
  keymaps.lua             general keymaps (save, clipboard, fzf-lua, git)
  lazy.lua                lazy.nvim bootstrap; imports every lua/plugins/*.lua
  lsp.lua                 diagnostics, server settings, which servers to enable, LSP keys
  devtools.lua            :DevTools — which external tools Neovim can see
lua/plugins/              one plugin spec per file
lazy-lock.json            pinned plugin commits
```

| Plugin file | Plugin | Role |
| --- | --- | --- |
| `catppuccin.lua` | catppuccin/nvim | colorscheme (mocha) |
| `lspconfig.lua` | nvim-lspconfig | server defaults for `vim.lsp.enable` |
| `treesitter.lua` | nvim-treesitter | parsers, highlighting, indent, folds |
| `conform.lua` | conform.nvim | format on save |
| `fzf-lua.lua` | fzf-lua | files, grep, buffers, help, git status |
| `mini.lua` | mini.nvim | files explorer, surround, statusline, icons, completion |
| `nvim-tree.lua` | nvim-tree | sidebar tree |
| `gitsigns.lua` | gitsigns.nvim | hunks, blame, staging |
| `diffview.lua` | diffview.nvim | full diffs and file history |
| `smart-splits.lua` | smart-splits.nvim + tmux backend | `Ctrl+h/j/k/l` across splits and tmux panes |
| `which-key.lua` | which-key.nvim | shows pending key combos |
| `render-markdown.lua` | render-markdown.nvim | renders Markdown in the buffer (raw text on the cursor line) |

## Keys (leader = `Space`)

| Keys | Action |
| --- | --- |
| `Space w` / `Space q` | save / close window |
| `Space h` · `Space uw` | clear search highlight · toggle soft wrap |
| `Space j` / `Space k` | move line or selection down / up |
| `Tab` / `Shift+Tab` (visual) | indent / outdent, keeping the selection |
| `Space ff` `fa` `fg` `fb` `fh` | files / all files (incl. ignored) / grep / buffers / help |
| `Space e` · `Space te` `tr` | mini.files · nvim-tree toggle / reveal current file |
| `Ctrl h/j/k/l` | move across splits and tmux panes |
| `gd` `K` · `Space lr` `rn` `ca` | definition, hover · references, rename, code action |
| `[d` `]d` · `Space ld` | previous/next diagnostic · line diagnostics |
| `Space cf` | format file/selection (also runs on save) |
| `Space y` `Y` `p` `P` | system clipboard yank / yank line / paste after / before |
| `Space gs` · `gD` `gu` `gS` `gH` `gC` | git status · diffview: HEAD / unstaged / staged / file history / close |
| `]h` `[h` · `Space gp` `gb` `ghs` `ghr` | hunks · preview, blame, stage, reset |
| `Space mp` · `Space mP` | Markdown: toggle rendering · rendered view in a side split |

Plain `y`/`p` use Neovim's own registers; only the `Space` variants touch the system
clipboard (`clipboard` is empty on purpose). Press `Space` and wait to see everything in which-key.

## Customize

### Options and keymaps

Edit `lua/config/options.lua` / `keymaps.lua`. Indentation per filetype is in
`autocmds.lua`. LSP keys are buffer-local and live in `lsp.lua` (`LspAttach`).

### Add a plugin

Create `lua/plugins/<name>.lua`; lazy.nvim picks it up on the next start.

```lua
-- lua/plugins/todo-comments.lua
return {
	{
		"folke/todo-comments.nvim",
		event = "BufReadPost",            -- lazy-load; omit for start-up plugins
		opts = {},                        -- passed to require("todo-comments").setup()
		keys = { { "<leader>ft", "<cmd>TodoQuickFix<CR>", desc = "List TODOs" } },
	},
}
```

Then restart Neovim (or `:Lazy`), and commit the updated `lazy-lock.json`.
Remove a plugin by deleting its file, then `:Lazy clean`.

### Add a language

1. **Server:** install the binary (via `packages/Brewfile`, `npm.txt`, `go.txt` or a conda
   env), then add `{ exe = "<binary>", id = "<lspconfig name>" }` to the server list in
   `lsp.lua`. Server-specific settings go in a `vim.lsp.config("<name>", { … })` call above it.
   Names: `:help lspconfig-all`.
2. **Syntax:** add the parser to the `install({ … })` list **and** the filetype to the
   `pattern = { … }` list in `treesitter.lua`.
3. **Formatter:** map the filetype in `formatters_by_ft` in `conform.lua` and make sure the
   formatter is installed. Formatters run on save; disable per buffer with
   `:lua vim.b.disable_autoformat = true` or globally with `vim.g.disable_autoformat = true`.
4. Check with `:checkhealth vim.lsp`, `:ConformInfo` and `:DevTools`.

Currently: gopls, pyright + ruff (Python, from the active conda env), ts_ls, lua_ls;
formatters goimports, ruff, prettier (project-local `node_modules`), stylua.

### Colorscheme

`catppuccin.lua` sets `flavour = "mocha"`. To switch themes, replace that file with another
colorscheme plugin and call `vim.cmd.colorscheme(...)` in its `config`. Keep tmux and
Ghostty in sync (see [`home/README.md`](../../../README.md)).

### Python environment

Pyright uses `$CONDA_PREFIX/bin/python` when you start Neovim inside an activated conda
env (`conda activate <env>; nvim`); otherwise it discovers one itself.

## Maintenance

| Task | How |
| --- | --- |
| Update plugins | `make update-nvim` (or `:Lazy sync`), then commit `lazy-lock.json` |
| Roll back plugins | `git checkout lazy-lock.json`, then `:Lazy restore` |
| Update parsers | `:TSUpdate` |
| Health | `:checkhealth`, `:checkhealth vim.lsp`, `:checkhealth smart-splits` |
| Missing tools | `:DevTools` |

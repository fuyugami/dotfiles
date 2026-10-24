local map = vim.keymap.set

-- ============================================
-- GENERAL
-- ============================================

map("n", "<leader>w", "<cmd>write<CR>", {
	desc = "Save file",
})

map("n", "<leader>q", "<cmd>quit<CR>", {
	desc = "Close window",
})

map("n", "<leader>h", "<cmd>nohlsearch<CR>", {
	desc = "Clear search highlights",
})

map("n", "<leader>uw", function()
	vim.wo.wrap = not vim.wo.wrap
	vim.notify("Soft wrap: " .. (vim.wo.wrap and "on" or "off"))
end, {
	desc = "Toggle soft wrap",
})

-- ============================================
-- MOVE LINES
-- ============================================

map("n", "<leader>j", "<cmd>move .+1<CR>==", {
	desc = "Move line down",
})

map("n", "<leader>k", "<cmd>move .-2<CR>==", {
	desc = "Move line up",
})

map("x", "<leader>j", ":move '>+1<CR>gv=gv", {
	desc = "Move selection down",
})

map("x", "<leader>k", ":move '<-2<CR>gv=gv", {
	desc = "Move selection up",
})

-- ============================================
-- NAVIGATION
-- ============================================

-- j/k navigate display rows when soft wrap is on.
-- Counts (e.g. 5j) still use logical lines.
map({ "n", "x" }, "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, {
	expr = true,
	desc = "Down displayed row",
})

map({ "n", "x" }, "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, {
	expr = true,
	desc = "Up displayed row",
})

-- Split/tmux pane navigation (<C-h/j/k/l>) lives in lua/plugins/smart-splits.lua.
-- [b / ]b buffer navigation is a Neovim 0.11+ default.

-- ============================================
-- CLIPBOARD: NEOVIM VS macOS
-- ============================================

-- Requires vim.opt.clipboard = "" in options.lua
--
-- Neovim internal registers:
--   y / yy  = copy internally
--   d / dd  = delete internally
--   p / P   = paste internally
--
-- macOS clipboard:
--   Space+y = copy to macOS clipboard
--   Space+Y = copy line to macOS clipboard
--   Space+p = paste macOS clipboard
--   Space+P = paste before cursor

-- Copy explicitly to macOS clipboard.
map({ "n", "x" }, "<leader>y", '"+y', {
	desc = "Copy to macOS clipboard",
})

map("n", "<leader>Y", '"+yy', {
	desc = "Copy line to macOS clipboard",
})

-- Paste from macOS clipboard after/before cursor.
map("n", "<leader>p", '"+p', {
	desc = "Paste macOS clipboard after cursor",
})

map("n", "<leader>P", '"+P', {
	desc = "Paste macOS clipboard before cursor",
})

-- Replace visual selection with macOS clipboard.
-- Delete selection to the black-hole register first
-- so repeated pastes preserve clipboard contents.
map("x", "<leader>p", '"_d"+P', {
	desc = "Replace selection from macOS clipboard",
})

-- ============================================
-- INDENT / OUTDENT VISUAL SELECTION
-- ============================================

-- Keep selection active after indenting.
map("x", "<Tab>", ">gv", {
	desc = "Indent selection",
})

map("x", "<S-Tab>", "<gv", {
	desc = "Outdent selection",
})

-- ============================================
-- PROJECT EXPLORER
-- ============================================

map("n", "<leader>e", function()
	require("mini.files").open(vim.fn.getcwd(), true)
end, {
	desc = "Open project explorer",
})

-- ============================================
-- FUZZY FINDING (fzf-lua)
-- ============================================

map("n", "<leader>ff", function()
	require("fzf-lua").files({
		hidden = false,
		no_ignore = false,
	})
end, {
	desc = "Find project file",
})

map("n", "<leader>fa", function()
	require("fzf-lua").files({
		hidden = true,
		no_ignore = true,
	})
end, {
	desc = "Find all project file",
})

map("n", "<leader>fg", function()
	require("fzf-lua").live_grep()
end, {
	desc = "Search project text",
})

map("n", "<leader>fb", function()
	require("fzf-lua").buffers()
end, {
	desc = "Find buffer",
})

map("n", "<leader>fh", function()
	require("fzf-lua").helptags()
end, {
	desc = "Search help",
})

-- ============================================
-- GIT
-- ============================================

map("n", "<leader>gs", function()
	require("fzf-lua").git_status()
end, {
	desc = "Git status",
})

-- Gitsigns and Diffview shortcuts are configured
-- inside lua/plugins/gitsigns.lua and diffview.lua.

-- Install lazy.nvim once. Plugins are downloaded on first launch.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local result = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Unable to install lazy.nvim: " .. result)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Automatically import every plugin specification in lua/plugins/*.lua.
-- Keep the existing lazy-lock.json in the configuration root.
require("lazy").setup({
  { import = "plugins" },
}, {
  checker = { enabled = false }, -- Update intentionally with :Lazy update
})

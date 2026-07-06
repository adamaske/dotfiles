local opt = vim.opt
vim.g.python3_host_prog = "C:\\Users\\adama\\miniconda3\\python.exe"
-- Line Numbers
opt.number = true
opt.relativenumber = false

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

vim.api.nvim_create_autocmd("Filetype", {
	pattern = { "svelte", "javascript", "typescript", "html", "css", "json" },
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
	end,
})

-- Prose: auto-wrap at 80 while typing (newline inserted at the last word
-- that fits). fo+=t wraps text, fo-=l makes it apply to lines that were
-- already long when insert started.
vim.api.nvim_create_autocmd("Filetype", {
	pattern = { "text", "markdown" },
	callback = function()
		vim.opt_local.textwidth = 80
		vim.opt_local.formatoptions:append("t")
		vim.opt_local.formatoptions:remove("l")
	end,
})

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Apperance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.colorcolumn = "80"
opt.scrolloff = 8
opt.wrap = false

-- Splits
opt.splitright = true
opt.splitbelow = true

-- System clipboard
opt.clipboard = "unnamedplus"

opt.undofile = true
opt.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	command = "checktime",
})

opt.updatetime = 250

opt.ruler = true

-- Suppress all deprecation warnings originating from rustaceanvim (Neovim 0.11 API lag)
local _deprecate = vim.deprecate
vim.deprecate = function(name, alt, version, plugin, backtrace)
	if debug.traceback():find("rustaceanvim", 1, true) then return end
	_deprecate(name, alt, version, plugin, backtrace)
end

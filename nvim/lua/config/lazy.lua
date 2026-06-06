-- Bootstrap lazy.nvim (auto-installs if not present)
local lazypath = vim.fn.stdpath("data") .. "\\lazy\\lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- Load lazy with our plugins folder
require("lazy").setup("config.plugins", {
  change_detection = {
    notify = false,
  },
  install = {
    colorscheme = { "habamax" },
  },
  ui = {
    border = "rounded",
  },
  rocks = {
    enabled = false,
  },
})

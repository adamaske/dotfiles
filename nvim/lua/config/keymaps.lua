local map = vim.keymap.set

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Replace Escape with jk
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Save File
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save File" })

-- Quit
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- Exit file
map("n", "<leader>pv", "<cmd>Ex<CR>", { desc = "Ex" })

--
--
-- Navigation
--
--
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper split" })

-- Resize
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase split height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease split height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease split width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase split width" })

-- Move Lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

-- Keep centered when jumping trhough search results
map("n", "n", "nzzzv", { desc = "Next search result(centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

--=====================
-- Buffers
-- ====================
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next Buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous Buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete Buffer" })

--==============
-- Clipboard
-- =============
-- Paste without overriding clipoard register
map("v", "<leader>p", '"_dP', { desc = "Paste without yanking" })

-- Delete without yanking
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

--=========
-- Splits
-- ========
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split Vertical" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split Horizontal" })
map("n", "<leader>se", "<cmd>wincmd =<CR>", { desc = "Equalize Split" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close Split" })

-- LSP splits
map("n", "<leader>gv", function()
	vim.cmd("vsplit")
	vim.lsp.buf.definition()
end, { desc = "Go to definition vertical split" })

map("n", "<leader>gs", function()
	vim.cmd("split")
	vim.lsp.buf.definition()
end, { desc = "Go to definition horizontal split" })

map("n", "<leader>gt", function()
	vim.cmd("tab split")
	vim.lsp.buf.definition()
end, { desc = "Go to definition tab split" })

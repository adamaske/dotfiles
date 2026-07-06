local map = vim.keymap.set

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Replace Escape with jk
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode" })

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
-- Seamless navigation between nvim splits and the multiplexer's panes.
-- nvim owns ctrl-hjkl: move within nvim splits, and at a split edge hand off to
-- the multiplexer. The handoff is ASYNC (jobstart, not system) so nvim never
-- freezes while herdr/psmux spawns — that blocking call was the "ctrl+l locks
-- up" symptom. From a non-nvim pane (shell/Claude) use the multiplexer's own
-- pane keys (herdr: prefix+h/j/k/l = ctrl+a then h/j/k/l).
--   herdr -> `herdr pane focus --current`   psmux -> `psmux select-pane`
local herdr = "C:/Users/adama/AppData/Local/Programs/Herdr/bin/herdr.exe"
local herdr_dir = { h = "left", j = "down", k = "up", l = "right" }
local psmux_dir = { h = "L", j = "D", k = "U", l = "R" }
local function pane_nav(dir)
	local prev = vim.api.nvim_get_current_win()
	vim.cmd.wincmd(dir)
	if prev ~= vim.api.nvim_get_current_win() then return end -- moved within nvim
	if vim.env.HERDR_PANE_ID and vim.fn.executable(herdr) == 1 then
		vim.fn.jobstart({ herdr, "pane", "focus", "--current", "--direction", herdr_dir[dir] })
	elseif vim.env.TMUX then
		vim.fn.jobstart({ "psmux", "select-pane", "-" .. psmux_dir[dir] })
	end
end
map("n", "<C-h>", function() pane_nav("h") end, { desc = "Nav left (nvim/herdr)" })
map("n", "<C-j>", function() pane_nav("j") end, { desc = "Nav down (nvim/herdr)" })
map("n", "<C-k>", function() pane_nav("k") end, { desc = "Nav up (nvim/herdr)" })
map("n", "<C-l>", function() pane_nav("l") end, { desc = "Nav right (nvim/herdr)" })

-- Same bindings in terminal mode (e.g. Claude pane)
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Move to left split" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Move to right split" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Move to lower split" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Move to upper split" })

-- Word-wise navigation with ctrl+arrows, clamped to the current line.
-- Default `w`/`b` wrap onto the next/previous line at a line's edge; here we do
-- the motion, and if it crossed a line boundary we instead land at the very end
-- (forward) or very start (backward) of the original line -- matching how most
-- editors treat Ctrl+Right / Ctrl+Left.
local function word_move(motion)
	local start = vim.api.nvim_win_get_cursor(0)
	vim.cmd("normal! " .. motion)
	local now = vim.api.nvim_win_get_cursor(0)
	if now[1] ~= start[1] then
		local col = motion == "w" and #vim.fn.getline(start[1]) or 0
		vim.api.nvim_win_set_cursor(0, { start[1], col })
	end
end
-- Insert mode only: normal mode keeps ctrl+arrows for split resizing (below).
map("i", "<C-Right>", function() word_move("w") end, { desc = "Word forward (clamped to line)" })
map("i", "<C-Left>", function() word_move("b") end, { desc = "Word back (clamped to line)" })

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

--=========
-- Reflow text to 80 columns
-- ========
-- gw = format motion, keeps cursor in place. Forces textwidth 80 so it
-- also works in filetypes where textwidth isn't set. In tex buffers a
-- structure-aware formatter runs instead: it puts \centering, \hline,
-- \begin/\end etc. on their own lines and leaves math/tables/verbatim alone.
local function reflow_80(visual)
	if vim.bo.filetype == "tex" then
		local first, last = 1, vim.fn.line("$")
		if visual then
			first = math.min(vim.fn.line("v"), vim.fn.line("."))
			last = math.max(vim.fn.line("v"), vim.fn.line("."))
			local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
			vim.api.nvim_feedkeys(esc, "n", false)
		end
		require("config.tex_format").format(first, last)
		return
	end
	local tw = vim.bo.textwidth
	vim.bo.textwidth = 80
	vim.cmd("normal! " .. (visual and "gw" or "gggwG"))
	vim.bo.textwidth = tw
end
map("n", "<leader>r8", function() reflow_80(false) end, { desc = "Reflow buffer to 80 cols" })
map("v", "<leader>r8", function() reflow_80(true) end, { desc = "Reflow selection to 80 cols" })

--============================================================
-- Run the current file (writes first; output in a bottom panel)
--   <leader>R   run     |   inside the panel: jk to exit term mode,
--   <C-h/j/k/l> to move out. Press <leader>R again to re-run.
--============================================================
local runners = {
	python = function(f)
		return { "python", f }
	end,
	rust = function()
		return { "cargo", "run" }
	end,
	lua = function(f)
		return { "nvim", "-l", f }
	end,
	javascript = function(f)
		return { "node", f }
	end,
	typescript = function(f)
		return { "node", f }
	end,
	sh = function(f)
		return { "bash", f }
	end,
	-- compile-then-run; wrapped in `cmd /c` so the && chains in one shell
	c = function(f, o)
		return { "cmd", "/c", ('gcc "%s" -o "%s" && "%s"'):format(f, o, o) }
	end,
	cpp = function(f, o)
		return { "cmd", "/c", ('g++ -std=c++20 "%s" -o "%s" && "%s"'):format(f, o, o) }
	end,
}

local runner_win
local function run_file()
	vim.cmd("silent! write")
	local build = runners[vim.bo.filetype]
	if not build then
		vim.notify("No runner for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
		return
	end
	local cmd = build(vim.fn.expand("%:p"), vim.fn.expand("%:p:r") .. ".exe")

	-- reuse the panel window if still open, else open one at the bottom
	if runner_win and vim.api.nvim_win_is_valid(runner_win) then
		vim.api.nvim_set_current_win(runner_win)
		vim.cmd("enew")
	else
		vim.cmd("botright 15split | enew")
		runner_win = vim.api.nvim_get_current_win()
	end

	vim.fn.jobstart(cmd, { term = true })
	vim.cmd("startinsert")
end

map("n", "<leader>R", run_file, { desc = "Run current file" })

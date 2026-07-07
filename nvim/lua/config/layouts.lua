-- tmux-style layout cycling for nvim windows (<leader>cl).
-- Cycles the current tabpage through tmux's five preset layouts, in tmux's
-- order. Strict tmux parity by choice: EVERY non-floating window is a pane
-- (files, terminals, quickfix, help). Plugin-managed windows (e.g. the Claude
-- terminal) may snap their own size back afterwards - accepted trade-off.
-- The herdr twin of this lives in ~/.config/herdr/layout-cycle.ps1.
local M = {}

local LAYOUTS = { "even-horizontal", "even-vertical", "main-horizontal", "main-vertical", "tiled" }
local MAIN_RATIO = 0.55 -- share of the screen the "main" pane gets

-- Non-floating windows of the current tabpage in tmux reading order (top->bottom,
-- left->right), with everything needed to recreate them after the rebuild.
local function collect()
	local wins = {}
	local cur = vim.api.nvim_get_current_win()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_config(win).relative == "" then
			local pos = vim.api.nvim_win_get_position(win)
			wins[#wins + 1] = {
				win = win,
				row = pos[1],
				col = pos[2],
				buf = vim.api.nvim_win_get_buf(win),
				cursor = vim.api.nvim_win_get_cursor(win),
				focused = win == cur,
			}
		end
	end
	table.sort(wins, function(a, b)
		if a.row ~= b.row then return a.row < b.row end
		return a.col < b.col
	end)
	return wins
end

-- Split off the current window and show entry's buffer in the new window,
-- which becomes the current window. pcall because deeply split layouts can
-- run out of room (E36) on small terminals.
local function open_split(cmd, entry)
	local ok = pcall(vim.cmd, cmd)
	if not ok then return nil end
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, entry.buf)
	pcall(vim.api.nvim_win_set_cursor, win, entry.cursor)
	return win
end

-- Build one of the preset layouts from `wins` (already ordered; wins[1] is the
-- anchor window that survived the teardown and is current). Returns the list
-- of created windows aligned with `wins`, or nil if a split failed.
local function build(layout, wins)
	local n = #wins
	local placed = { wins[1].win }

	if layout == "even-horizontal" or layout == "even-vertical" then
		local cmd = layout == "even-horizontal" and "botright vsplit" or "botright split"
		for i = 2, n do
			placed[i] = open_split(cmd, wins[i])
			if not placed[i] then return nil end
		end
		vim.cmd("wincmd =")
	elseif layout == "main-vertical" or layout == "main-horizontal" then
		-- wins[1] is the main pane; the rest form a stack (right) or row (below).
		local first = layout == "main-vertical" and "botright vsplit" or "botright split"
		local rest = layout == "main-vertical" and "belowright split" or "belowright vsplit"
		for i = 2, n do
			placed[i] = open_split(i == 2 and first or rest, wins[i])
			if not placed[i] then return nil end
		end
		vim.cmd("wincmd =")
		if layout == "main-vertical" then
			vim.api.nvim_win_set_width(placed[1], math.floor(vim.o.columns * MAIN_RATIO))
		else
			local total = vim.api.nvim_win_get_height(placed[1]) + vim.api.nvim_win_get_height(placed[2])
			vim.api.nvim_win_set_height(placed[1], math.floor(total * MAIN_RATIO))
		end
	else -- tiled: grid in reading order, last row may be short
		local cols = math.ceil(math.sqrt(n))
		local rows = math.ceil(n / cols)
		-- Row leaders first, while each region still spans the full width.
		for r = 2, rows do
			vim.api.nvim_set_current_win(placed[(r - 2) * cols + 1])
			placed[(r - 1) * cols + 1] = open_split("botright split", wins[(r - 1) * cols + 1])
			if not placed[(r - 1) * cols + 1] then return nil end
		end
		-- Then fill each row rightwards.
		for r = 1, rows do
			local first_i = (r - 1) * cols + 1
			local last_i = math.min(r * cols, n)
			vim.api.nvim_set_current_win(placed[first_i])
			for i = first_i + 1, last_i do
				placed[i] = open_split("belowright vsplit", wins[i])
				if not placed[i] then return nil end
			end
		end
		vim.cmd("wincmd =")
	end
	return placed
end

function M.cycle()
	local wins = collect()
	if #wins < 2 then
		vim.notify("Layout cycle: need at least 2 windows", vim.log.levels.INFO)
		return
	end

	local next_i = ((vim.t.layout_cycle or 0) % #LAYOUTS) + 1
	local layout = LAYOUTS[next_i]

	-- The focused pane becomes the main pane in the two main-* layouts.
	if layout == "main-vertical" or layout == "main-horizontal" then
		for i, w in ipairs(wins) do
			if w.focused then
				table.insert(wins, 1, table.remove(wins, i))
				break
			end
		end
	end

	-- Teardown: keep wins[1]'s window, close the rest (buffers stay loaded).
	vim.api.nvim_set_current_win(wins[1].win)
	for i = 2, #wins do
		pcall(vim.api.nvim_win_close, wins[i].win, true)
	end

	local placed = build(layout, wins)
	if not placed then
		vim.notify("Layout cycle: not enough room for " .. layout, vim.log.levels.WARN)
		return
	end
	vim.t.layout_cycle = next_i

	for i, w in ipairs(wins) do
		if w.focused then
			vim.api.nvim_set_current_win(placed[i])
			break
		end
	end
	vim.notify("Layout: " .. layout, vim.log.levels.INFO)
end

return M

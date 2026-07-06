-- Structure-aware reflow for LaTeX, bound to <leader>r8 in tex buffers
-- (see keymaps.lua; other filetypes use plain gw there).
--
-- Two passes over the range:
--   1. Structural commands (\centering, \hline, \begin/\end, \item, ...)
--      are pulled onto their own lines.
--   2. Prose paragraphs are rewrapped at 80 columns. Any line starting
--      with a command or comment is a boundary that is never joined
--      across, and the content of verbatim/math/table environments is
--      left untouched (except pass 1 still splits \hline & friends
--      inside tables, which is where they usually live).

local M = {}

local WIDTH = 80

-- Commands that should sit alone on a line: newline before AND after.
local OWN_LINE = {
	"centering", "raggedright", "raggedleft",
	"hline", "toprule", "midrule", "bottomrule",
	"newpage", "clearpage", "pagebreak",
	"bigskip", "medskip", "smallskip",
	"maketitle", "tableofcontents", "listoffigures", "listoftables",
}

-- Commands that should start a new line (their argument may be followed
-- by more text on the same line, so only break before them).
local BREAK_BEFORE = { "item", "label", "caption", "includegraphics", "input", "include" }

-- Sectioning commands: own line including their {title} argument.
local SECTION = { "chapter", "section", "subsection", "subsubsection", "paragraph" }

-- Environments whose body is never reformatted at all.
local VERBATIM = {
	verbatim = true, ["verbatim*"] = true,
	lstlisting = true, minted = true, comment = true,
}

-- Environments whose lines must not be joined/rewrapped (rows and math
-- are line-structured), though pass 1 may still split commands there.
local NO_WRAP = {
	tabular = true, ["tabular*"] = true, tabularx = true, longtable = true,
	array = true, tikzpicture = true,
	equation = true, ["equation*"] = true, align = true, ["align*"] = true,
	gather = true, ["gather*"] = true, multline = true, ["multline*"] = true,
	eqnarray = true, cases = true, split = true,
	matrix = true, pmatrix = true, bmatrix = true,
	vmatrix = true, Vmatrix = true, Bmatrix = true,
}
for env in pairs(VERBATIM) do
	NO_WRAP[env] = true
end

-- How many \begin{...}/\end{...} of the given env set a line contains.
local function env_delta(line, set)
	local b, e = 0, 0
	for env in line:gmatch("\\begin{([^}]+)}") do
		if set[env] then b = b + 1 end
	end
	for env in line:gmatch("\\end{([^}]+)}") do
		if set[env] then e = e + 1 end
	end
	return b, e
end

-- Pass 1 on a single line: insert \n around structural commands.
local function split_commands(line)
	for _, name in ipairs(OWN_LINE) do
		line = line:gsub("([^\n \t])[ \t]*(\\" .. name .. "%f[%A])", "%1\n%2")
		line = line:gsub("(\\" .. name .. "%f[%A])[ \t]*([^\n \t])", "%1\n%2")
	end
	for _, name in ipairs(BREAK_BEFORE) do
		line = line:gsub("([^\n \t])[ \t]*(\\" .. name .. "%f[%A])", "%1\n%2")
	end
	for _, name in ipairs(SECTION) do
		line = line:gsub("([^\n \t])[ \t]*(\\" .. name .. "%f[%A])", "%1\n%2")
		-- break after the {title} arg; [short]{long} variant first
		line = line:gsub("(\\" .. name .. "%*?%b[]%b{})[ \t]*([^\n \t])", "%1\n%2")
		line = line:gsub("(\\" .. name .. "%*?%b{})[ \t]*([^\n \t])", "%1\n%2")
	end
	line = line:gsub("([^\n \t])[ \t]*(\\begin%f[%A])", "%1\n%2")
	line = line:gsub("([^\n \t])[ \t]*(\\end%f[%A])", "%1\n%2")
	-- after \begin{env} unless its own args ({cols}, [pos]) follow
	line = line:gsub("(\\begin%b{})[ \t]*([^\n \t{%[])", "%1\n%2")
	line = line:gsub("(\\end%b{})[ \t]*([^\n \t])", "%1\n%2")
	return line
end

function M.format(first, last)
	local raw = vim.api.nvim_buf_get_lines(0, first - 1, last, false)

	-- pass 1: own-line commands (skipping comments and verbatim bodies)
	local lines = {}
	local verb = 0
	for _, line in ipairs(raw) do
		local vb, ve = env_delta(line, VERBATIM)
		if verb > 0 or line:match("^%s*%%") or line:match("^%s*$") then
			lines[#lines + 1] = line
		else
			local indent = line:match("^[ \t]*")
			for piece in (split_commands(line) .. "\n"):gmatch("(.-)\n") do
				piece = piece:match("^%s*(.-)%s*$")
				if piece ~= "" then lines[#lines + 1] = indent .. piece end
			end
		end
		verb = verb + vb - ve
	end

	-- pass 2: rewrap prose runs at WIDTH
	local out, run, run_indent = {}, {}, ""
	local nowrap = 0
	local function wrap_into(src, indent)
		local words = {}
		for _, l in ipairs(src) do
			for w in l:gmatch("%S+") do words[#words + 1] = w end
		end
		local cur
		for _, w in ipairs(words) do
			if not cur then
				cur = indent .. w
			elseif #cur + #w + 1 <= WIDTH then
				cur = cur .. " " .. w
			else
				out[#out + 1] = cur
				cur = indent .. w
			end
		end
		if cur then out[#out + 1] = cur end
	end
	local function flush()
		if #run == 0 then return end
		wrap_into(run, run_indent)
		run = {}
	end
	for _, line in ipairs(lines) do
		local nb, ne = env_delta(line, NO_WRAP)
		local trimmed = line:match("^%s*(.-)%s*$")
		local barrier = nowrap > 0 or trimmed == ""
			or trimmed:match("^\\") or trimmed:match("^%%")
		if barrier then
			flush()
			-- a long command-initial line (e.g. \item with lots of text)
			-- still gets wrapped in place -- just never joined to neighbors
			if #line > WIDTH and nowrap == 0 and not trimmed:match("^%%") then
				wrap_into({ line }, line:match("^[ \t]*"))
			else
				out[#out + 1] = line
			end
		else
			if #run == 0 then run_indent = line:match("^[ \t]*") end
			run[#run + 1] = line
			-- a forced break (\\) must stay at the end of its line
			if trimmed:match("\\\\%s*$") then flush() end
		end
		nowrap = nowrap + nb - ne
	end
	flush()

	vim.api.nvim_buf_set_lines(0, first - 1, last, false, out)
end

return M

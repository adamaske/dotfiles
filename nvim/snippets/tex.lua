-- LaTeX structure snippets with self-filling labels.
--
-- Loaded by the from_lua loader in plugins/completion.lua; they show up in
-- the blink.cmp menu (type the trigger, accept, Tab between placeholders).
-- The \label{} slug is a function node fed by the title/caption you type,
-- so `sec` + "Helmholtz Decomposition" yields
-- \label{sec:helmholtz-decomposition} with zero extra keystrokes — it
-- updates live thanks to update_events in the LuaSnip setup.

local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta

-- "Helmholtz Decomposition (1858)" -> "helmholtz-decomposition-1858"
local function slug(args)
	local text = (args[1][1] or ""):lower()
	text = text:gsub("%s+", "-"):gsub("[^%w%-]", ""):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
	return text
end

-- \section{<title>} \label{sec:<slug of title>}
local function sectioning(trig, cmd, prefix, dscr)
	return s(
		{ trig = trig, dscr = dscr },
		fmta("\\" .. cmd .. [[{<>}
\label{]] .. prefix .. [[:<>}

<>]], { i(1), f(slug, { 1 }), i(0) })
	)
end

return {
	sectioning("sec", "section", "sec", "\\section with auto label"),
	sectioning("sub", "subsection", "sub", "\\subsection with auto label"),
	sectioning("ssub", "subsubsection", "ssub", "\\subsubsection with auto label"),

	-- equation environment; label typed by hand (equations have no title to slug)
	s(
		{ trig = "eq", dscr = "equation environment with label" },
		fmta(
			[[\begin{equation}
	<>
	\label{eq:<>}
\end{equation}
<>]],
			{ i(1), i(2, "name"), i(0) }
		)
	),

	-- figure; label slugged from the caption
	s(
		{ trig = "fig", dscr = "figure environment, label auto-filled from caption" },
		fmta(
			[[\begin{figure}[htbp]
	\centering
	\includegraphics[width=<>\textwidth]{<>}
	\caption{<>}
	\label{fig:<>}
\end{figure}
<>]],
			{ i(1, "0.8"), i(2), i(3), f(slug, { 3 }), i(0) }
		)
	),

	-- table; label slugged from the caption
	s(
		{ trig = "tab", dscr = "table environment, label auto-filled from caption" },
		fmta(
			[[\begin{table}[htbp]
	\centering
	\caption{<>}
	\label{tab:<>}
	\begin{tabular}{<>}
		<>
	\end{tabular}
\end{table}
<>]],
			{ i(1), f(slug, { 1 }), i(2, "lcc"), i(3), i(0) }
		)
	),

	-- generic environment; closing name mirrors the opening one as you type
	s(
		{ trig = "beg", dscr = "\\begin{...}\\end{...} with mirrored name" },
		fmta(
			[[\begin{<>}
	<>
\end{<>}]],
			{ i(1), i(0), rep(1) }
		)
	),
}

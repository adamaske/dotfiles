return {
	-- VimTeX: the LaTeX editing/build/viewer layer.
	-- texlab (see lsp.lua) handles completion/diagnostics; VimTeX owns the
	-- motions, compile-on-save, SyncTeX forward/inverse search, and TOC.
	{
		"lervag/vimtex",
		lazy = false, -- needs to load before the tex ftplugin fires; do not lazy-load
		init = function()
			-- Compiler: latexmk (ships with MiKTeX). Continuous build on write.
			vim.g.vimtex_compiler_method = "latexmk"

			-- In-terminal live preview: we render the PDF inside a wezterm pane
			-- with `tdf`, which auto-reloads on every rebuild. VimTeX's own
			-- viewer integration is therefore unused; <leader>lv (below) opens
			-- the tdf pane instead. SumatraPDF is still available as a fallback
			-- GUI viewer via :VimtexView if you ever want SyncTeX forward search.
			vim.g.vimtex_view_method = "general"
			vim.g.vimtex_view_general_viewer = "SumatraPDF"
			-- -inverse-search registers the reverse jump with Sumatra: double-click
			-- anywhere in the PDF and the running Neovim jumps to that source line
			-- (VimtexInverseSearch finds the live nvim instance via its server pipe).
			vim.g.vimtex_view_general_options = table.concat({
				"-reuse-instance",
				"-forward-search @tex @line @pdf",
				[[-inverse-search "nvim --headless -c \"VimtexInverseSearch %l '%f'\""]],
			}, " ")

			-- Continuous compilation (latexmk -pvc) is VimTeX's default mode:
			-- <leader>ll starts it, and it rebuilds the PDF on every :w, which
			-- is what drives tdf's live reload.
			vim.g.vimtex_compiler_latexmk = {
				continuous = 1,
				aux_dir = "build", -- keep .aux/.log/.bbl etc out of the source dir; PDF stays beside the .tex
				options = {
					"-verbose",
					"-file-line-error",
					"-synctex=1",
					"-interaction=nonstopmode",
				},
			}

			-- Render \alpha as α, super/subscripts, etc. — off in the line you
			-- are editing so you can still see the raw source.
			vim.g.vimtex_syntax_conceal = {
				accents = 1,
				ligatures = 1,
				cites = 1,
				fancy = 1,
				greek = 1,
				math_bounds = 1,
				math_delimiters = 1,
				math_fracs = 1,
				math_super_sub = 1,
				math_symbols = 1,
				sections = 0,
				styles = 1,
			}

			-- Quickfix: don't jump on open, and ignore common noisy warnings.
			vim.g.vimtex_quickfix_mode = 0
			vim.g.vimtex_quickfix_ignore_filters = {
				"Underfull",
				"Overfull",
				"LaTeX Warning: .\\+ float specifier changed",
			}

			-- Use texlab for completion; VimTeX's omnicomplete would collide.
			vim.g.vimtex_complete_enabled = 0
		end,
		config = function()
			-- conceallevel is what actually shows the pretty symbols.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "tex",
				callback = function()
					vim.opt_local.conceallevel = 2
					vim.opt_local.wrap = false -- soft wrap made vertical jumps confusing
					vim.opt_local.spell = true
					vim.opt_local.spelllang = "en_us"
				end,
			})
		end,
		keys = {
			{ "<leader>ll", "<cmd>VimtexCompile<cr>", ft = "tex", desc = "LaTeX: toggle compile" },
			-- Primary viewer: SumatraPDF in its own window. Crisp, auto-reloads on
			-- every latexmk rebuild, and SyncTeX forward search jumps it to the
			-- cursor (inverse search: click PDF -> back to source, once configured).
			{ "<leader>lv", "<cmd>VimtexView<cr>", ft = "tex", desc = "LaTeX: view PDF (SumatraPDF)" },
			-- Optional in-terminal crisp preview: a native WezTerm pane rendering
			-- the PDF via Kitty graphics, live-reloading on rebuild. (herdr panes
			-- can't show images; this splits the WezTerm pane herdr runs in.)
			{
				"<leader>li",
				function()
					require("config.latex_preview").open("kitty")
				end,
				ft = "tex",
				desc = "LaTeX: preview in WezTerm pane",
			},
			{ "<leader>lt", "<cmd>VimtexTocToggle<cr>", ft = "tex", desc = "LaTeX: table of contents" },
			{ "<leader>lk", "<cmd>VimtexStop<cr>", ft = "tex", desc = "LaTeX: stop compile" },
			{ "<leader>lc", "<cmd>VimtexClean<cr>", ft = "tex", desc = "LaTeX: clean aux files" },
			{ "<leader>le", "<cmd>VimtexErrors<cr>", ft = "tex", desc = "LaTeX: show errors" },
		},
	},

	-- Gilles Castel-style auto-expanding math snippets: `mk` → inline math,
	-- `dm` → display math, `//` → \frac{}{}, `sr` → ^2, `td` → ^{}, matrices,
	-- greek letters, etc. They fire automatically (no Tab needed) and only
	-- inside math zones, so prose is never mangled. Complements our own
	-- structure snippets in <config>/snippets/tex.lua (sec/fig/eq/... with
	-- self-filling labels).
	{
		"iurimateus/luasnip-latex-snippets.nvim",
		dependencies = { "L3MON4D3/LuaSnip", "lervag/vimtex" },
		ft = "tex",
		config = function()
			-- use_treesitter=false → VimTeX's syntax layer decides "am I in math?"
			-- (no latex treesitter parser needed, and it matches our conceal setup)
			require("luasnip-latex-snippets").setup({ use_treesitter = false })
		end,
	},
}

return {
	-- LuaSnip: snippet engine. Configured standalone (not inline in blink's
	-- dependencies) so the LaTeX snippet plugins can depend on it and get the
	-- same instance with autosnippets already enabled.
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip").setup({
				-- Required for the auto-expanding LaTeX math snippets (mk, //, sr, ...)
				enable_autosnippets = true,
				-- Re-evaluate function nodes while typing, so e.g. the \label{}
				-- slug in the tex snippets fills in live as you type the title
				update_events = "TextChanged,TextChangedI",
			})
			-- VSCode-style collection (friendly-snippets)
			require("luasnip.loaders.from_vscode").lazy_load()
			-- Our own Lua snippets: <config>/snippets/<filetype>.lua
			require("luasnip.loaders.from_lua").lazy_load({
				paths = { vim.fn.stdpath("config") .. "/snippets" },
			})
		end,
	},

	-- blink.cmp: completion engine. Replaces nvim-cmp — faster, typo-tolerant
	-- fuzzy matching (Rust matcher), signature help, and saner ranking, which
	-- is what makes texlab's label/citation completion actually pleasant.
	{
		"saghen/blink.cmp",
		version = "1.*", -- release tag → downloads the prebuilt Rust fuzzy matcher
		event = "InsertEnter",
		dependencies = { "L3MON4D3/LuaSnip" },
		opts = {
			snippets = { preset = "luasnip" },

			-- Same muscle memory as the old nvim-cmp setup
			keymap = {
				preset = "none",
				["<C-k>"] = { "select_prev", "fallback" },
				["<C-j>"] = { "select_next", "fallback" },
				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<CR>"] = { "accept", "fallback" }, -- only accepts an explicitly selected item
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
			},

			completion = {
				-- Don't preselect: <CR> is a plain newline unless you picked an item
				list = { selection = { preselect = false, auto_insert = true } },
				menu = {
					border = "rounded",
					draw = {
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "source_name" },
						},
					},
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = { border = "rounded" },
				},
				-- Adds () after functions etc. — replaces the old autopairs/cmp hook
				accept = { auto_brackets = { enabled = true } },
			},

			-- Function signature popup while typing arguments
			signature = { enabled = true, window = { border = "rounded" } },

			sources = {
				default = { "lsp", "snippets", "path", "buffer" },
			},

			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
	},
}

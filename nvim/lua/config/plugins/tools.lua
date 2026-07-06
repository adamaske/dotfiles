return {
	-- Highlight and navigate TODO/FIXME/NOTE comments
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next TODO",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Prev TODO",
			},
			{ "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
		},
		opts = {
			signs = true,
			keywords = {
				FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
				TODO = { icon = " ", color = "info" },
				HACK = { icon = " ", color = "warning" },
				WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
				NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
			},
		},
	},

	-- Better diagnostics list
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (project)",
			},
			{
				"<leader>xb",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Diagnostics (buffer)",
			},
			{ "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
			{ "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP definitions" },
			{ "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
		},
		opts = {
			modes = {
				diagnostics = {
					auto_close = true, -- close when no more diagnostics
				},
			},
		},
	},

	-- Fast file switching
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{
				"<leader>ha",
				function()
					require("harpoon"):list():add()
				end,
				desc = "Harpoon add file",
			},
			{
				"<leader>hh",
				function()
					local harpoon = require("harpoon")
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				desc = "Harpoon menu",
			},
			-- Jump to marked files 1-4
			{
				"<leader>1",
				function()
					require("harpoon"):list():select(1)
				end,
				desc = "Harpoon file 1",
			},
			{
				"<leader>2",
				function()
					require("harpoon"):list():select(2)
				end,
				desc = "Harpoon file 2",
			},
			{
				"<leader>3",
				function()
					require("harpoon"):list():select(3)
				end,
				desc = "Harpoon file 3",
			},
			{
				"<leader>4",
				function()
					require("harpoon"):list():select(4)
				end,
				desc = "Harpoon file 4",
			},
			-- Cycle through marked files
			{
				"<leader>hn",
				function()
					require("harpoon"):list():next()
				end,
				desc = "Harpoon next",
			},
			{
				"<leader>hp",
				function()
					require("harpoon"):list():prev()
				end,
				desc = "Harpoon prev",
			},
		},
		config = function()
			require("harpoon"):setup({
				settings = {
					save_on_toggle = true,
					sync_on_ui_close = true,
				},
			})
		end,
	},

	-- LSP progress as unobtrusive corner spinners
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {
			progress = {
				display = {
					render_limit = 4,
					done_ttl = 2,
				},
			},
			notification = {
				window = {
					winblend = 0,
				},
			},
		},
	},

	-- Notification toasts + toggleable history buffer
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			notifier = {
				enabled = true,
				timeout = 5000,
				style = "fancy",
				width = { min = 40, max = 0.5 },
				height = { min = 1, max = 0.3 },
			},
			lazygit = {
				enabled = true,
			},
			-- Inline images in markdown buffers (kitty graphics protocol).
			-- Works in a plain WezTerm tab; herdr/psmux panes swallow the
			-- protocol, so use markdown-preview.nvim (<leader>mp) there.
			image = {
				enabled = true,
				doc = {
					inline = true, -- render at the image link position
					float = true, -- fallback float on cursor hover
					max_width = 80,
					max_height = 40,
				},
			},
			-- Render the notification history as a classic bottom panel/split
			-- instead of the default centered float. <leader>n still toggles it.
			styles = {
				notification_history = {
					border = "top",
					position = "bottom",
					height = 0.3,
					width = 0, -- full width (ignored for bottom splits anyway)
					title = " Notification History ",
					title_pos = "center",
				},
			},
		},
		keys = {
			{
				"<leader>n",
				function()
					Snacks.notifier.show_history()
				end,
				desc = "Notification history",
			},
			{
				"<leader>lg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},
		},
	},

	-- Polished UI for LSP markdown rendering
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		opts = {
			cmdline = {
				enabled = false,
			},
			messages = {
				enabled = false,
			},
			popupmenu = {
				enabled = false,
			},
			notify = {
				enabled = false, -- snacks.notifier owns vim.notify
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
				progress = {
					enabled = false, -- fidget handles LSP progress
				},
				hover = {
					enabled = false,
				},
				signature = {
					enabled = false,
				},
			},
			presets = {
				lsp_doc_border = true,
			},
			routes = {
				{
					filter = {
						event = "msg_show",
						find = "search hit BOTTOM",
					},
					opts = { skip = true },
				},
			},
		},
	},
}

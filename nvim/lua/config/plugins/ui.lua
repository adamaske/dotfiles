return {

	{
		"sainnhe/gruvbox-material",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.gruvbox_material_background = "hard"
			vim.g.gruvbox_material_palette = "original"
			vim.g.gruvbox_material_enable_italic = true
			vim.g.gruvbox_material_transparent_background = 1
			vim.cmd("colorscheme gruvbox-material")
		end,
	}, -- File explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- file icons
			"MunifTanjim/nui.nvim", -- UI component library
		},
		cmd = "Neotree",
		keys = {
			{
				"<leader>e",
				function()
					local state = require("neo-tree.sources.manager").get_state("filesystem")
					local win = state and state.winid
					if win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() == win then
						vim.cmd("Neotree close")
					else
						vim.cmd("Neotree focus reveal=false")
					end
				end,
				desc = "Toggle/focus file explorer",
			},
			{ "<leader>s", group = "splits" },
			{ "<leader>g", group = "goto" },
		},
		opts = {
			close_if_last_window = true,
			window = {
				width = 30,
				mappings = {
					["<space>"] = "none", -- don't let neo-tree hijack our leader
				},
			},
			filesystem = {
				window = {
					mappings = {
						["-"] = "navigate_up",
						["."] = "set_root",
					},
				},
				filtered_items = {
					visible = false,
					hide_dotfiles = false, -- show dotfiles like .env
					hide_gitignored = true,
				},
				follow_current_file = {
					enabled = true, -- highlight current file in tree
				},
				use_libuv_file_watcher = true,
			},
			default_component_configs = {
				git_status = {
					symbols = {
						added = "✚",
						modified = "",
						deleted = "✖",
						renamed = "󰁕",
						untracked = "",
						ignored = "",
						unstaged = "󰄱",
						staged = "",
						conflict = "",
					},
				},
			},
		},
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		opts = {
			options = {
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = true, -- single statusline across all splits
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { { "filename", path = 1 } }, -- relative path
				lualine_x = { "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},

	-- Shows available keymaps when you press leader
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			delay = 400, -- ms before popup appears
			icons = {
				mappings = true,
			},
			spec = {
				-- Group labels — organises your Space menu into sections
				{ "<leader>f", group = "find" },
				{ "<leader>r", group = "rust" },
				{ "<leader>h", group = "harpoon" }, -- was mislabeled "git hunks"
				{ "<leader>H", group = "git" }, -- gitsigns hunks
				{ "<leader>b", group = "buffers" },
				{ "<leader>D", group = "debug" },
				{ "<leader>t", group = "test" },
				{ "<leader>a", group = "ai/claude" },
				{ "<leader>x", group = "diagnostics" },
				{ "<leader>v", group = "venv" },
			},
		},
	},
}

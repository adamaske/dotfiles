return {

	{
		"zootedb0t/citruszest.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("citruszest").setup({
				option = {
					transparent = true,
					bold = false,
					italic = true,
				},
				style = {},
			})
			vim.cmd("colorscheme citruszest")
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
			{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
			{ "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus file explorer" },
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
				{ "<leader>h", group = "git hunks" },
				{ "<leader>b", group = "buffers" },
			},
		},
	},
}

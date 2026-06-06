return {
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim", -- utility library telescope needs
			{
				"nvim-telescope/telescope-fzf-native.nvim", -- faster fuzzy sorting
				build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake -E copy build/Release/libfzf.dll build/libfzf.dll",
			},
		},
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
			{ "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
			{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
			{ "<leader>fw", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					preview = { treesitter = false },
					-- Where results appear
					layout_strategy = "horizontal",
					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.55,
						},
					},
					sorting_strategy = "ascending",
					winblend = 0,
					border = true,

					-- Keymaps inside telescope
					mappings = {
						i = {
							["<C-k>"] = actions.move_selection_previous,
							["<C-j>"] = actions.move_selection_next,
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
							["<Esc>"] = actions.close,
						},
					},

					-- Ignore these when searching files
					file_ignore_patterns = {
						"node_modules",
						".git/",
						"target/", -- Rust build output
						"dist/",
						".svelte-kit/",
					},
				},

				pickers = {
					find_files = {
						hidden = true, -- show dotfiles
					},
				},
			})

			-- Load fzf extension for faster sorting
			if not pcall(telescope.load_extension, "fzf") then
				vim.notify("telescope-fzf not available, using default sorter", vim.log.levels.WARN)
			end
		end,
	},
}

return {
	-- Jump anywhere on screen with a 2-3 key label
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
			-- treesitter select in normal/operator only ("x"/visual is left to nvim-surround's S)
			{ "S", mode = { "n", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
			{ "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
			{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter search" },
			{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle flash search" },
		},
	},

	-- Add/change/delete surrounding pairs: ysiw" , cs"' , ds( , (visual) S)
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		opts = {}, -- defaults: ys/ds/cs in normal, S in visual
	},

	-- Indentation guides + highlighted current scope
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			indent = { char = "│" },
			scope = { enabled = true, show_start = false, show_end = false },
			exclude = {
				filetypes = {
					"help",
					"neo-tree",
					"Trouble",
					"trouble",
					"lazy",
					"mason",
					"snacks_notif_history",
					"snacks_terminal",
					"snacks_dashboard",
				},
			},
		},
	},
}

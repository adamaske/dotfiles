return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local map = vim.keymap.set
				local function o(desc)
					return { buffer = bufnr, desc = desc }
				end

				-- Navigate between hunks
				map("n", "]h", function()
					gs.nav_hunk("next")
				end, o("Next hunk"))
				map("n", "[h", function()
					gs.nav_hunk("prev")
				end, o("Prev hunk"))

				-- Hunk actions (capital H namespace — <leader>h is harpoon)
				map("n", "<leader>Hs", gs.stage_hunk, o("Stage hunk"))
				map("n", "<leader>Hr", gs.reset_hunk, o("Reset hunk"))
				map("v", "<leader>Hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, o("Stage selection"))
				map("v", "<leader>Hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, o("Reset selection"))
				map("n", "<leader>HS", gs.stage_buffer, o("Stage buffer"))
				map("n", "<leader>HR", gs.reset_buffer, o("Reset buffer"))
				map("n", "<leader>Hp", gs.preview_hunk, o("Preview hunk"))
				map("n", "<leader>Hd", gs.diffthis, o("Diff this"))
				map("n", "<leader>Hb", function()
					gs.blame_line({ full = true })
				end, o("Blame line"))
				map("n", "<leader>Ht", gs.toggle_current_line_blame, o("Toggle line blame"))
			end,
		},
	},
}

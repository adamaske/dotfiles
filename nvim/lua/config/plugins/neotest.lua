return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-neotest/neotest-python",
			"mfussenegger/nvim-dap-python", -- lets <leader>td debug the nearest test
		},
		keys = {
			{ "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
			{ "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
			{ "<leader>ta", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run all tests" },
			{ "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last test" },
			{ "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
			{ "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle test summary" },
			{ "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show test output" },
			{ "<leader>tp", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
			{ "<leader>tw", function() require("neotest").watch.toggle() end, desc = "Toggle test watch" },
			{ "]n", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
			{ "[n", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev failed test" },
		},
		config = function()
			local adapters = {
				require("neotest-python")({
					runner = "pytest",
					dap = { justMyCode = false },
				}),
			}

			-- Rust tests come from rustaceanvim's own neotest adapter (no extra plugin).
			-- It only resolves once rustaceanvim has loaded (i.e. a .rs buffer is open),
			-- which is always the case when you're actually running Rust tests.
			local ok, rust = pcall(require, "rustaceanvim.neotest")
			if ok then
				table.insert(adapters, rust)
			end

			require("neotest").setup({ adapters = adapters })
		end,
	},
}

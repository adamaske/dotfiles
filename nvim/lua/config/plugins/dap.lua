return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
			"theHamsta/nvim-dap-virtual-text",
			"mfussenegger/nvim-dap-python",
		},
		keys = {
			-- Core loop on function keys (standard DAP convention)
			{ "<F5>", function() require("dap").continue() end, desc = "Debug: start / continue" },
			{ "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
			{ "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
			{ "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
			{ "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
			-- Extras under <leader>D ("D" avoids the <leader>d delete-without-yank map)
			{ "<leader>Db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
			{ "<leader>Dc", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
			{ "<leader>Dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
			{ "<leader>Dl", function() require("dap").run_last() end, desc = "Run last" },
			{ "<leader>Du", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
			{ "<leader>De", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Eval expression" },
			{ "<leader>Dt", function() require("dap").terminate() end, desc = "Terminate session" },
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()
			require("nvim-dap-virtual-text").setup()

			-- Auto open/close the debug UI around a session
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Breakpoint / stopped-line signs
			vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })

			-- Python: use debugpy that Mason installed
			local data = vim.fn.stdpath("data")
			require("dap-python").setup(data .. "/mason/packages/debugpy/venv/Scripts/python.exe")

			-- C / C++ via codelldb (Mason). rustaceanvim auto-detects the same adapter.
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = data .. "/mason/packages/codelldb/extension/adapter/codelldb.exe",
					args = { "--port", "${port}" },
				},
			}
			dap.configurations.cpp = {
				{
					name = "Launch executable (codelldb)",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "\\", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}
			dap.configurations.c = dap.configurations.cpp
		end,
	},
}

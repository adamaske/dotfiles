return {
	-- Mason: installs language servers
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	-- Bridge between mason and lspconfig
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"taplo", -- TOML / Cargo.toml
				"svelte", -- Svelte
				"ts_ls", -- TypeScript / JavaScript
				"html", -- HTML
				"cssls", -- CSS
				"jsonls", -- JSON
				"basedpyright", -- Python LSP (stricter, better-maintained pyright fork)
				"ruff", -- Python linter + formatter LSP
				"clangd", -- C / C++
			},
			automatic_installation = true,
		},
	},

	-- Auto-install non-LSP Mason tools (formatters, linters)
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"ruff", -- Python formatter + linter
				"clang-format", -- C / C++ formatter
				"codelldb", -- DAP adapter for Rust + C/C++ debugging
				"debugpy", -- DAP adapter for Python debugging
			},
		},
	},

	-- Native LSP setup (Neovim 0.11+)
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-- Let cmp-nvim-lsp advertise completion capabilities to all servers
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			vim.lsp.config("*", { capabilities = capabilities }) -- Shared on_attach keymaps

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local map = vim.keymap.set
					local opts = { buffer = bufnr }

					map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
					map(
						"n",
						"gD",
						vim.lsp.buf.declaration,
						vim.tbl_extend("force", opts, { desc = "Go to declaration" })
					)
					map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Find references" }))
					map(
						"n",
						"gi",
						vim.lsp.buf.implementation,
						vim.tbl_extend("force", opts, { desc = "Go to implementation" })
					)
					map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover docs" }))
					map(
						"n",
						"<leader>rn",
						vim.lsp.buf.rename,
						vim.tbl_extend("force", opts, { desc = "Rename symbol" })
					)
					map(
						"n",
						"<leader>ca",
						vim.lsp.buf.code_action,
						vim.tbl_extend("force", opts, { desc = "Code action" })
					)
					map("n", "<leader>f", vim.lsp.buf.format, vim.tbl_extend("force", opts, { desc = "Format file" }))

					-- Diagnostics
					map(
						"n",
						"[d",
						vim.diagnostic.goto_prev,
						vim.tbl_extend("force", opts, { desc = "Previous diagnostic" })
					)
					map(
						"n",
						"]d",
						vim.diagnostic.goto_next,
						vim.tbl_extend("force", opts, { desc = "Next diagnostic" })
					)
					map(
						"n",
						"<leader>xf",
						vim.diagnostic.open_float,
						vim.tbl_extend("force", opts, { desc = "Show diagnostic float" })
					)

					-- Inlay hints (inferred types / param names) for any server that supports them
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client:supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
						map("n", "<leader>ih", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
						end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
					end
				end,
			})

			-- Diagnostic display
			vim.diagnostic.config({
				virtual_text = true,
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			-- Global capabilities for all servers
			vim.lsp.config("*", { capabilities = capabilities })

			-- basedpyright analysis settings — real type checking, but quiet about
			-- third-party stubs so you aren't drowned in noise.
			vim.lsp.config("basedpyright", {
				settings = {
					basedpyright = {
						analysis = {
							typeCheckingMode = "standard", -- was effectively "off"; standard gives useful signal
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							diagnosticMode = "openFilesOnly", -- snappier than scanning the whole workspace
							autoImportCompletions = true,
							inlayHints = {
								variableTypes = true,
								functionReturnTypes = true,
								callArgumentNames = true,
							},
							diagnosticSeverityOverrides = {
								-- keep these off so missing third-party stubs don't spam you
								reportMissingTypeStubs = "none",
								reportUnknownMemberType = "none",
								reportUnknownVariableType = "none",
							},
						},
					},
				},
			})

			-- clangd: C / C++. Needs a compile_commands.json for non-trivial projects
			-- (CMake: configure with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON).
			vim.lsp.config("clangd", {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=never",
					"--completion-style=detailed",
				},
			})

			-- texlab: LaTeX LSP (citation/label completion, cross-refs, chktex
			-- diagnostics). Binary comes from scoop (main/texlab), not mason.
			-- VimTeX drives the actual build/viewer, so leave texlab's build off.
			vim.lsp.config("texlab", {
				settings = {
					texlab = {
						build = { onSave = false },
						chktex = { onOpenAndSave = true, onEdit = false },
					},
				},
			})

			-- Enable servers — nvim-lspconfig ships lsp/*.lua files that provide
			-- the cmd/filetypes/root_markers for each one
			vim.lsp.enable({
				"taplo",
				"svelte",
				"ts_ls",
				"html",
				"cssls",
				"jsonls",
				"basedpyright",
				"ruff",
				"clangd",
				"texlab",
			})
		end,
	},
}

return {
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    ft = { "rust" },  -- only loads when opening a .rs file
    config = function()
      vim.g.rustaceanvim = {
        -- LSP settings
        server = {
          on_attach = function(_, bufnr)
            local map = vim.keymap.set
            local opts = { buffer = bufnr }

            -- Rust-specific commands
            map("n", "<leader>rr", "<cmd>RustLsp runnables<cr>",      vim.tbl_extend("force", opts, { desc = "Rust runnables" }))
            map("n", "<leader>rt", "<cmd>RustLsp testables<cr>",      vim.tbl_extend("force", opts, { desc = "Rust testables" }))
            map("n", "<leader>rm", "<cmd>RustLsp expandMacro<cr>",    vim.tbl_extend("force", opts, { desc = "Expand macro" }))
            map("n", "<leader>rc", "<cmd>RustLsp openCargo<cr>",      vim.tbl_extend("force", opts, { desc = "Open Cargo.toml" }))
            map("n", "<leader>rd", "<cmd>RustLsp debuggables<cr>",    vim.tbl_extend("force", opts, { desc = "Rust debuggables" }))
            map("n", "<leader>rh", "<cmd>RustLsp hover actions<cr>",  vim.tbl_extend("force", opts, { desc = "Rust hover actions" }))
            map("n", "<leader>re", "<cmd>RustLsp explainError<cr>",   vim.tbl_extend("force", opts, { desc = "Explain error" }))
            map("n", "<leader>ro", "<cmd>RustLsp renderDiagnostic<cr>", vim.tbl_extend("force", opts, { desc = "Render diagnostic" }))

            -- These still apply for Rust too
            map("n", "gd",         vim.lsp.buf.definition,     vim.tbl_extend("force", opts, { desc = "Go to definition" }))
            map("n", "K",          vim.lsp.buf.hover,          vim.tbl_extend("force", opts, { desc = "Hover docs" }))
            map("n", "<leader>ca", vim.lsp.buf.code_action,    vim.tbl_extend("force", opts, { desc = "Code action" }))
            map("n", "<leader>rn", vim.lsp.buf.rename,         vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
            map("n", "<leader>f",  vim.lsp.buf.format,         vim.tbl_extend("force", opts, { desc = "Format file" }))
            map("n", "[d",         vim.diagnostic.goto_prev,   vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
            map("n", "]d",         vim.diagnostic.goto_next,   vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
            map("n", "<leader>e",  vim.diagnostic.open_float,  vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))
          end,

          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,       -- check all feature flags
                loadOutDirsFromCheck = true,
              },
              checkOnSave = true,
              check = {
                command = "clippy",       -- use clippy instead of plain check
              },
              inlayHints = {
                bindingModeHints         = { enable = true },
                chainingHints            = { enable = true },
                closingBraceHints        = { enable = true },
                parameterHints           = { enable = true },
                typeHints                = { enable = true },
              },
              procMacro = {
                enable = true,            -- needed for Tauri macros
              },
            },
          },
        },
      }
    end,
  },
}

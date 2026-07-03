return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- stable branch; the `main` rewrite ignores ensure_installed/indent
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },

    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua",
          "rust",
          "toml",
          "svelte",
          "javascript",
          "typescript",
          "html",
          "css",
          "json",
          "markdown",
          "markdown_inline",
          "bash",
          "python",
          "c",
          "cpp",
          "cmake",
          "make",
          "bibtex",
        },
        highlight = {
          enable = true, -- was missing entirely
          -- VimTeX's syntax layer owns tex files: the conceal rendering
          -- (α, ², fractions) and quickfix parsing depend on it. Keep the
          -- latex parser out even if it gets installed later.
          disable = { "latex" },
        },
        indent = { enable = true },
      })
    end,
  },
}

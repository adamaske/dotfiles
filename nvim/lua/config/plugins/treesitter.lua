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
        },
        highlight = { enable = true }, -- was missing entirely
        indent = { enable = true },
      })
    end,
  },
}

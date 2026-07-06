return {
	-- Render markdown beautifully inside Neovim
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		ft = { "markdown" },
		opts = {
			heading = {
				enabled = true,
				sign = true,
				icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			},
			code = {
				enabled = true,
				sign = true,
				style = "full", -- full block styling for code blocks
				border = "thin",
			},
			dash = { enabled = true }, -- renders --- as a full line
			bullet = { enabled = true }, -- renders list bullets as icons
			checkbox = {
				enabled = true,
				unchecked = { icon = "󰄱 " },
				checked = { icon = "󰱒 " },
			},
			table = {
				enabled = true,
				style = "full",
			},
			link = {
				enabled = true,
				image = "󰥶 ",
				hyperlink = "󰌹 ",
			},
			quote = { enabled = true },
			win_options = {
				conceallevel = {
					default = vim.api.nvim_get_option_value("conceallevel", {}),
					rendered = 3, -- hide markdown syntax when rendering
				},
			},
		},
	},

	-- Live rendered preview in the browser (images, mermaid, katex, scroll sync)
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		keys = {
			{ "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview", ft = "markdown" },
		},
	},

	-- Better markdown editing experience
	{
		"bullets-vim/bullets.vim",
		ft = { "markdown" },
		-- Automatically continues list items when pressing Enter
		-- Renumbers ordered lists automatically
	},

	-- Table editing made easy
	{
		"dhruvasagar/vim-table-mode",
		ft = { "markdown" },
		init = function()
			vim.g.table_mode_corner = "|" -- markdown compatible tables
		end,
		keys = {
			{ "<leader>tm", "<cmd>TableModeToggle<cr>", desc = "Toggle table mode", ft = "markdown" },
			{ "<leader>tr", "<cmd>TableModeRealign<cr>", desc = "Realign table", ft = "markdown" },
			{ "<leader>tdd", "<cmd>TableModeDeleteRow<cr>", desc = "Delete row", ft = "markdown" },
			{ "<leader>tdc", "<cmd>TableModeDeleteColumn<cr>", desc = "Delete column", ft = "markdown" },
		},
	},

	-- Markdown-specific keymaps and motions
	{
		"tadmccorkle/markdown.nvim",
		ft = { "markdown" },
		opts = {
			-- Toggle checkboxes with enter
			on_attach = function(bufnr)
				local map = vim.keymap.set
				local opts = { buffer = bufnr }

				-- Toggle checkbox [ ] / [x]
				map(
					"n",
					"<leader>mt",
					"<cmd>MDTaskToggle<cr>",
					vim.tbl_extend("force", opts, { desc = "Toggle checkbox" })
				)

				-- Navigate headings
				map("n", "]]", "<cmd>MDHeadingNext<cr>", vim.tbl_extend("force", opts, { desc = "Next heading" }))
				map("n", "[[", "<cmd>MDHeadingPrev<cr>", vim.tbl_extend("force", opts, { desc = "Prev heading" }))

				-- Inline formatting in visual mode
				map(
					"v",
					"<leader>mb",
					"<cmd>MDInlineToggle bold<cr>",
					vim.tbl_extend("force", opts, { desc = "Toggle bold" })
				)
				map(
					"v",
					"<leader>mi",
					"<cmd>MDInlineToggle italic<cr>",
					vim.tbl_extend("force", opts, { desc = "Toggle italic" })
				)
				map(
					"v",
					"<leader>mc",
					"<cmd>MDInlineToggle code<cr>",
					vim.tbl_extend("force", opts, { desc = "Toggle inline code" })
				)
				map(
					"v",
					"<leader>ms",
					"<cmd>MDInlineToggle strikethrough<cr>",
					vim.tbl_extend("force", opts, { desc = "Toggle strikethrough" })
				)
			end,
		},
	},
}

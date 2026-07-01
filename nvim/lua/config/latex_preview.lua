-- Opens the live LaTeX preview in a dedicated native WezTerm pane.
--
-- Why WezTerm and not a herdr pane: herdr (0.7.1-preview) swallows terminal image
-- protocols in its panes, so images never render there; a native WezTerm pane
-- renders the Kitty graphics protocol crisply. herdr runs inside a single WezTerm
-- pane, so we split that pane at the WezTerm level to sit a real image-capable
-- pane beside it. The watcher re-renders on every latexmk rebuild.
--
-- Focus note: this pane is outside herdr's control, so move into it with WezTerm's
-- own nav (leader ctrl+b then arrow), not herdr's ctrl+a prefix.
local M = {}

function M.open(format)
	format = format or "kitty"

	-- Prefer VimTeX's known output PDF; fall back to <name>.pdf next to the file.
	local out = vim.b.vimtex and vim.b.vimtex.out and vim.b.vimtex:out()
	if not out or out == "" then
		out = vim.fn.expand("%:p:r") .. ".pdf"
	end

	local script = vim.fn.expand("~/.config/scripts/latex-preview.ps1")

	-- Split the WezTerm pane that hosts herdr and run the watcher in the new
	-- native pane. All herdr panes share one underlying WezTerm pane, so
	-- $WEZTERM_PANE is that pane's id. detach so Neovim doesn't block on the
	-- long-lived preview process.
	local pane = vim.env.WEZTERM_PANE or "0"
	vim.fn.jobstart({
		"wezterm", "cli", "split-pane", "--right", "--percent", "42", "--pane-id", pane,
		"--", "pwsh", "-NoProfile", "-File", script, out, "-Format", format,
	}, { detach = true })
end

return M

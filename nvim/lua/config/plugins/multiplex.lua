-- vim-tmux-navigator removed: on Windows it parses psmux's $TMUX env var and
-- calls `tmux -S /tmp/psmux-<pid>/default select-pane ...`, but psmux's real
-- socket is C:\Users\adama\.psmux\default — so the call hits the wrong socket
-- and silently no-ops (you get stuck in nvim, especially on Ctrl-l).
--
-- Seamless nvim <-> psmux navigation now lives in lua/config/keymaps.lua
-- (pane_nav), which hands off to `psmux select-pane` at the split edge — that
-- resolves psmux's own socket correctly. The psmux side (~/.config/psmux/.psmux.conf)
-- keeps the `bind -n C-h/j/k/l` root binds for the shell-pane direction.
return {}

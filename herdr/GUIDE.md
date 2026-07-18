# herdr — user guide (your setup)

herdr is a **terminal workspace manager for AI coding agents** — a tmux-style
multiplexer that runs inside WezTerm and is *aware of what each pane is doing*
(whether a Claude in a pane is working, waiting, or done). It is your primary
multiplexer now; psmux is kept dormant as a fallback.

- **Binary:** `C:\Users\adama\AppData\Local\Programs\Herdr\bin\herdr.exe` (on PATH as `herdr`)
- **Config:** `~/.config/herdr/config.toml`  ·  **Logs:** `~/.config/herdr/herdr*.log`
- **Version:** 0.7.1-preview (preview channel) — it's beta, expect occasional churn.
- **Prefix:** `ctrl+a` (your tmux muscle memory; WezTerm's leader is `ctrl+b`).

> Throughout this guide, **`prefix`** = `ctrl+a`. "`prefix+w`" means: press `ctrl+a`,
> release, then `w`. (Upstream default prefix is `ctrl+b`; you overrode it.)

---

## 1. Core model

```
Server (headless, persistent)  ─ owns everything, survives client detach
└─ Session ("default")         ─ one per machine for you
   └─ Workspace                ─ a project (NIRWizard, config, …); shown in sidebar
      └─ Tab                   ─ a view within a workspace
         └─ Pane               ─ a real terminal (split right/down)
            └─ Agent           ─ claude/etc. running in a pane, with live state
```

The **server** keeps running after you close the window; `herdr` (the client)
re-attaches to it. Detaching with `prefix+q` leaves all panes alive.

---

## 2. Launching

No premade workspaces — you create and manage them live inside herdr
(`prefix+shift+n` etc.); they persist on the server between attaches.

| How | What it does |
|---|---|
| **`Win+T`** / **`Win+Shift+H`** | Open herdr in a fresh WezTerm window (attaches the session) |
| `herd` | (in any pwsh) ensure the server is up and attach |
| `herd <label>` | focus an existing workspace by label, then attach |
| `herd-list` | print workspace labels |
| `herd-close <label>` | close a workspace (kills its panes) |
| `herdr` | attach the default session directly |

The komorebi startup script pre-warms the herdr server at login (no workspace
creation). The `herd*` helpers live in `~/.config/herdr/herd.ps1`.

---

## 3. Keybinding reference (prefix = `ctrl+a`)

### Workspaces
| Key | Action |
|---|---|
| `prefix+w` | workspace picker |
| `prefix+shift+n` | new workspace |
| `prefix+shift+w` | rename workspace |
| `prefix+shift+d` | close workspace |
| `prefix+g` | goto / session navigator (fuzzy-jump anywhere) |

### Tabs
| Key | Action |
|---|---|
| `prefix+c` | new tab |
| `prefix+n` / `prefix+p` | next / previous tab |
| `prefix+1`…`prefix+9` | jump to tab N |
| `prefix+shift+t` | rename tab |
| `prefix+shift+x` | close tab |

### Panes
| Key | Action |
|---|---|
| `prefix+h/j/k/l` | focus pane left/down/up/right |
| `ctrl+h/j/k/l` | **seamless** move — nvim splits *and* herdr panes (see §4) |
| `prefix+v` | split right (vertical) |
| `prefix+minus` | split down (horizontal) |
| `prefix+z` | zoom (fullscreen) focused pane |
| `prefix+r` | resize mode |
| `prefix+x` | close pane |
| `prefix+shift+p` | rename pane |
| `prefix+tab` / `prefix+shift+tab` | cycle panes |
| `prefix+space` | **your custom:** cycle tab through the 5 tmux layouts (`layout-cycle.ps1`) |

### Agents (Claude) — see §5
| Key | Action |
|---|---|
| `prefix+alt+1`…`9` | focus the Nth agent in the priority queue (`prefix+alt+1` = most urgent) |
| `prefix+alt+j` / `prefix+alt+k` | next / previous agent |
| `prefix+o` | jump to the pane that raised the last notification |

### Worktrees — see §8
| Key | Action |
|---|---|
| `prefix+shift+g` | new worktree → new workspace for a branch |
| `prefix+shift+o` | open an existing worktree |
| `prefix+alt+d` | remove a worktree (with confirm) |

### System
| Key | Action |
|---|---|
| `prefix+b` | toggle sidebar (agent dashboard) |
| `prefix+s` | settings UI |
| `prefix+?` | help — shows every active binding |
| `prefix+e` | edit scrollback (see §6) |
| `prefix+shift+r` | reload config.toml live |
| `prefix+q` | detach (server keeps running) |
| `prefix+alt+g` | **your custom:** run lazygit in a throwaway pane |

> Tip: `prefix+?` is the source of truth for *your* live bindings on this build.

---

## 4. Neovim navigation

`ctrl+h/j/k/l` moves between nvim splits, and **at a split edge crosses into the
adjacent herdr pane** (e.g. from nvim into the Claude pane on the right). herdr is
not vim-aware, so nvim owns these keys and hands off to herdr at the edge via
`herdr pane focus`. This lives in `nvim/lua/config/keymaps.lua` (`pane_nav`) and
also falls back to psmux if you ever run that instead. From a **non-nvim** pane
(a shell or Claude), use `prefix+h/j/k/l`.

---

## 5. Agents & Claude Code (the reason to use herdr)

herdr watches each Claude's transcript (via the installed hook) and shows its
**state** everywhere:

- **States:** `idle` (waiting), `working` (processing), `blocked` (needs your
  input), `done` (finished, stays flagged until you look). A blocked agent makes
  its pane/tab/workspace look blocked.
- **Where you see it:** pane border labels (`show_agent_labels_on_pane_borders`),
  the sidebar (`prefix+b`) ordered by **priority** (most-urgent first), and the
  workspace picker.

### What's now configured for you
- `prefix+alt+1` → jump straight to the **most urgent** agent (a blocked Claude).
  `prefix+alt+j/k` cycle through agents.
- **Notifications:** a background Claude going blocked/done now raises a Windows
  toast (`[ui.toast] delivery="system"`) and a sound (`[ui.sound] enabled=true`).
  If system toasts misbehave on your build, set `delivery="herdr"` for in-app
  toasts. `prefix+o` jumps to whatever just notified.

### Daily workflow
1. `Win+T` → attach herdr, pick/create a workspace (e.g. nvim left, Claude right).
2. Work in nvim; `ctrl+l` to hop to Claude, `ctrl+h` back.
3. Kick off long Claude tasks across workspaces, then watch the **sidebar**
   (`prefix+b`): whoever needs you floats to the top. `prefix+alt+1` to jump there.

### Scripting Claude (the socket API)
```powershell
$h = 'C:\Users\adama\AppData\Local\Programs\Herdr\bin\herdr.exe'
& $h agent list                                   # all agents + states
& $h wait agent-status <pane_id> --status done --timeout 1800000   # block until finished
& $h notification show "Claude done" --sound done # toast + sound from a script
& $h pane read <pane_id> --source recent --lines 40  # read a pane's output
& $h agent send <target> "yes"                    # send literal text to an agent
```

### Optional: a Claude Code statusline
Add to `~/.claude/settings.json` so each pane shows model + folder next to herdr's
border state. (Optional polish — paste only if you want it.)
```json
"statusLine": { "type": "command",
  "command": "pwsh -NoProfile -Command \"$d=$input|ConvertFrom-Json; \\\"$($d.model.display_name) | $(Split-Path $d.workspace.current_dir -Leaf)\\\"\"" }
```

---

## 6. Copy / scrollback

- **`prefix+e`** — edit scrollback (the supported path on this build).
- **Mouse wheel** — scroll a pane (`ui.mouse_scroll_lines`).
- The docs mention a `prefix+[` vim-style copy mode (h/j/k/l move, `v`/Space
  select, `y`/Enter copy, `q`/Esc exit) — verify it on your build with `prefix+?`,
  as it isn't in this version's default keymap.
- **Selecting text with the mouse:** herdr captures the mouse; hold a modifier
  (`ui.right_click_passthrough_modifier`) or use `prefix+e` for clean copies.

---

## 7. Persistence — what survives

| Event | Processes | Layout | Screen | Agent convo |
|---|---|---|---|---|
| **Detach** (`prefix+q`) / reattach | ✅ kept | ✅ | ✅ | ✅ |
| **Server restart / reboot** | ❌ gone | ✅ restored | only if `pane_history` | only via agent resume |

So after a **reboot**, herdr restores your workspace *shape* (empty pwsh shells in
the right folders) but does **not** re-run nvim/claude/etc. — you re-issue those
commands yourself in the restored panes. `resume_agents_on_restore` is on, so
integrated Claude panes can resume their conversation.

(`pane_history` is intentionally `false` — it only repaints old text and writes
pane contents, including secrets, to disk.)

---

## 8. Worktrees — parallel agents on different branches

The clean way to run several Claudes at once without them clobbering each other's
files: each gets its own git worktree + workspace.

- `prefix+shift+g` → type a branch → herdr creates/checks out the branch in an
  isolated worktree (under `~/herdr-worktrees`) and opens it as a new workspace.
- `prefix+shift+o` reopen, `prefix+alt+d` remove.
- Launch a Claude in each; the sidebar aggregates all their states.

```powershell
& $h worktree create --workspace <id> --branch feat/x --base main --focus
& $h agent start claude --workspace <id> --split down -- claude
```

---

## 9. Scriptable CLI (socket API)

Everything the UI does is scriptable — ideal for orchestrating agents.

```
herdr status [--json]                     # is the server up?
herdr workspace list|create|focus|close|rename
herdr tab     list|create|focus|close|rename
herdr pane    list|split|focus|zoom|resize|read|run|send-text|send-keys|close
herdr agent   list|read|send|focus|rename|wait|start
herdr wait    output <pane> --match <text> | agent-status <pane> --status <s>
herdr notification show <title> [--body] [--sound none|done|request]
herdr worktree list|create|open|remove
herdr session list|attach|stop|delete
herdr server  stop|reload-config|live-handoff
herdr integration status [--outdated-only]
```

`pane run <id> "<cmd>"` sends a command + Enter; `pane send-text` sends literal
text; `pane read --source recent --lines N` captures output.

---

## 10. Config quick-reference (`~/.config/herdr/config.toml`)

```toml
[theme]   name = "gruvbox"           # built-ins: catppuccin, tokyo-night, nord, dracula, …
[terminal] default_shell = "pwsh"    # new_cwd = "follow"|"home"|"current"|"<path>"
[keys]    prefix = "ctrl+a"          # + focus_agent / worktree binds (already set)
[ui]      show_agent_labels_on_pane_borders = true
          agent_panel_sort = "priority"   # or "spaces" (grouped by workspace)
[ui.toast] delivery = "system"       # "off"|"herdr"|"terminal"|"system"
[ui.sound] enabled = true            # done sound on finish, request sound on needs-input
[worktrees] directory = "~/herdr-worktrees"
[update]  channel = "preview"        # "stable" for fewer builds
```
Custom command bindings:
```toml
[[keys.command]]
key = "prefix+alt+g"
type = "pane"        # "pane" temp pane | "shell" detached | "plugin_action"
command = "lazygit"
```
Apply edits live: `prefix+shift+r` (or `herdr server reload-config`).

---

## 11. Maintenance

- **Update:** `herdr update --handoff` (keeps live panes during the update).
- **Channel:** `herdr channel set stable` (or `preview`).
- **Integrations:** `herdr integration status` — Claude should read `current`.
  Re-run `herdr integration install claude` if it ever drifts.
- **Reset keys:** `herdr config reset-keys` (backs up config.toml first).

---

## 12. Your files & rollback

| File | Purpose |
|---|---|
| `~/.config/herdr/config.toml` | herdr config (gruvbox, ctrl+a, agent/worktree/notify) |
| `~/.config/herdr/herd.ps1` | `herd`/`herd-list`/`herd-close` helpers (dot-sourced in profile) |
| `~/.config/herdr/layout-cycle.ps1` | `prefix+space` tmux-style layout cycling (nvim twin: `<leader>sc`) |
| `~/.config/komorebi/start-komorebi.ps1` | login autostart (pre-warms the herdr server) |
| `~/.config/komorebi/komorebi.ahk` | `Win+T` / `Win+Shift+H` → attach herdr |
| `~/.config/nvim/lua/config/keymaps.lua` | `pane_nav` (nvim↔herdr ctrl-hjkl) |

**Fallback to psmux** (untouched): its config and `ws`/`Start-AllWorkspaces` still
work; point the AHK `Win+T` at `ws`, the nvim nav already auto-detects psmux
(`$TMUX`), and add `Start-AllWorkspaces` back to start-komorebi.ps1.

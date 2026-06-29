# yazi cheat sheet

Launch with **`y`** (quits + cd's to where you ended up). Inside yazi press **`~`**
or **`F1`** for the live, version-accurate keymap. Theme: gruvbox. Text/code files
open in **nvim**; other files open with the default app.

> Customised vs yazi defaults: **`z` = zoxide**, **`Z` = fzf** (yazi's default is the
> reverse) — so `z` matches your shell's zoxide. Set in `keymap.toml`.

## Navigate
| key | action |
|---|---|
| `k` / `↑` · `j` / `↓` | up · down |
| `h` / `←` | parent directory |
| `l` / `→` / `Enter` | enter directory / open file |
| `H` · `L` | back · forward (history) |
| `gg` · `G` | top · bottom |
| `Ctrl+u` · `Ctrl+d` | half page up · down |
| `Ctrl+b` · `Ctrl+f` | full page up · down |
| `K` · `J` | scroll the preview up · down |
| `Tab` | peek / spot the hovered file |

## Jump
| key | action |
|---|---|
| `gh` | home `~` |
| `gc` | `~/.config` |
| `gd` | `~/Downloads` |
| `g` then `Space` | type a path to jump to |
| `gf` | follow the hovered symlink |
| `z` | **zoxide** — jump to a frecent directory |
| `Z` | **fzf** — fuzzy-find any file/dir below and jump |

## Select
| key | action |
|---|---|
| `Space` | toggle-select current + move down |
| `v` · `V` | visual select · visual *unselect* mode |
| `Ctrl+a` · `Ctrl+r` | select all · invert selection |
| `Esc` | clear selection / cancel search |

## File operations
| key | action |
|---|---|
| `a` | create file (end with `/` for a directory) |
| `A` | bulk-create |
| `r` | rename |
| `d` · `D` | trash · delete permanently |
| `y` · `x` | copy (yank) · cut |
| `p` · `P` | paste · paste overwriting |
| `Y` / `X` | cancel the yank |
| `-` · `_` | symlink (absolute · relative) |
| `Ctrl+-` | hardlink |

## Copy a path to the clipboard (`c` then…)
| key | action |
|---|---|
| `cc` | full path |
| `cd` | directory |
| `cf` | filename |
| `cn` | filename without extension |

## Open / shell
| key | action |
|---|---|
| `o` / `Enter` | open |
| `O` | open with… (pick an app) |
| `;` | run a shell command |
| `:` | run a shell command and wait for it |

## Find / filter / search
| key | action |
|---|---|
| `f` | filter the current listing |
| `/` · `?` | find next · previous (then `n` / `N`) |
| `s` | search by **name** (fd, recursive) |
| `S` | search by **content** (ripgrep) |
| `Ctrl+s` | cancel the search |

## Tabs
| key | action |
|---|---|
| `tt` | new tab in CWD |
| `tr` | rename tab |
| `1`–`9` | switch to tab N |
| `[` · `]` | previous · next tab |
| `{` · `}` | swap tab with previous · next |

## View / sort
| key | action |
|---|---|
| `.` | toggle hidden files |
| `,n`/`,N` `,s`/`,S` `,m`/`,M` `,e`/`,E` `,a`/`,A` `,r` | sort: natural / size / mtime / ext / alpha (asc/desc) · random |
| `m` then `s`/`p`/`b`/`m`/`o`/`n` | linemode: size / perms / btime / mtime / owner / none |
| `w` | task manager |

## Quit
| key | action |
|---|---|
| `q` | quit (the `y` wrapper cd's you here) |
| `Q` | quit **without** changing directory |
| `Ctrl+c` | close current tab (or quit if last) |
| `Ctrl+z` | suspend |
| `~` / `F1` | help (live keymap) |

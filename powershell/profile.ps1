Invoke-Expression (&starship init powershell)

Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -MaximumHistoryCount 100000
Set-PSReadLineOption -HistoryNoDuplicates
# Inline command prediction (the grey suggestion text). Inside a multiplexer like
# psmux (which sets $TERM), PSReadLine resets PredictionSource to None *after* the
# profile runs — so setting it directly here doesn't stick. Defer it to the first
# idle (after PSReadLine has settled), which is the timing that actually holds.
Register-EngineEvent PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
} | Out-Null
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# ── Editor (mirrors zsh EDITOR/VISUAL=nvim) ──────────────────────────────────
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

# ── Aliases / functions (ported from ~/.zshrc) ───────────────────────────────
Set-Alias -Name cat -Value bat -Option AllScope -Force
function v { nvim @args }                # v -> nvim
function g { git @args }                 # g -> git
function o { Invoke-Item @args }         # o -> open (xdg-open)
del alias:ls
function ls { eza --icons --group-directories-first @args }
function ll { eza -l  --icons --group-directories-first @args }
function la { eza -la --icons --group-directories-first @args }

# lf with cd-on-quit (mirrors the zsh lf() wrapper)
function lf {
    $tmp = New-TemporaryFile
    lf.exe -last-dir-path "$tmp" @args
    $dir = Get-Content $tmp -ErrorAction SilentlyContinue
    Remove-Item $tmp -ErrorAction SilentlyContinue
    if ($dir -and (Test-Path $dir)) { Set-Location $dir }
}

function cdf {
    $dir = Get-ChildItem -Directory | Select-Object -ExpandProperty Name | fzf --layout=reverse --height=40% --border
    if ($dir) {
        Set-Location $dir
    }
}

# yazi with cd-on-quit: `q` quits and cd's to yazi's last dir; `Q` quits without.
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}

# zoxide: smarter cd. `z <partial>` jumps to a frecent dir, `zi` picks one with fzf.
# (Plain `cd` is unchanged; zoxide just learns dirs as you move around — which also
# feeds yazi's `z` zoxide jump.)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# psmux dev-session launcher: provides `ws <name>`  (mirrors tmux sessions.sh)
. "$HOME\.config\psmux\workspaces.ps1"

# herdr workspace launcher (trial): provides `herd <name>`
. "$HOME\.config\herdr\herd.ps1"

fastfetch --logo scientific
Write-Host ""


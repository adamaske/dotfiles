# =============================================================================
#  herd.ps1 — thin herdr helpers. No premade workspaces: workspaces are created
#  and managed live inside herdr (prefix+shift+n etc.); these just make the
#  server reachable and let you attach/close from any pwsh.
#
#  Usage:  herd                 -> attach the herdr TUI (lists nothing, just attaches)
#          herd <label>         -> focus an existing workspace by label, then attach
#          herd-list            -> print workspace labels
#          herd-close <label>   -> close a workspace by label (kills its panes)
# =============================================================================

function Get-HerdrExe {
    if (Get-Command herdr -ErrorAction SilentlyContinue) { return 'herdr' }
    return 'C:\Users\adama\AppData\Local\Programs\Herdr\bin\herdr.exe'
}

# Make sure the background server is up and REACHABLE before any CLI call.
# (Gate on `herdr status` — the socket file isn't a reliable filesystem check on
# Windows. The CLI subcommands need a running server or they fail with
# "Os NotFound" and you get spurious pane send-text/send-keys usage errors.)
function Ensure-HerdrServer {
    $exe = Get-HerdrExe
    if ((& $exe status 2>$null) -match 'status:\s*running') { return $true }
    Start-Process -FilePath $exe -ArgumentList 'server' -WindowStyle Hidden
    for ($i = 0; $i -lt 50; $i++) {                 # wait up to ~10s
        Start-Sleep -Milliseconds 200
        if ((& $exe status 2>$null) -match 'status:\s*running') { return $true }
    }
    Write-Host "herd: herdr server did not come up." -ForegroundColor Yellow
    return $false
}

# Attach the herdr TUI; with a label, focus that (already existing) workspace first.
function herd {
    param([Parameter(Position = 0)][string]$Name)
    $exe = Get-HerdrExe
    if (-not (Ensure-HerdrServer)) { return }
    if ($Name) {
        $ws = (& $exe workspace list 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue).result.workspaces |
              Where-Object { $_.label -eq $Name }
        if (-not $ws) {
            Write-Host "herd: no workspace labelled '$Name' — create it live in herdr (prefix+shift+n)."
            Write-Host "Existing: $((herd-list) -join ', ')"
            return
        }
        & $exe workspace focus @($ws)[0].workspace_id 2>$null | Out-Null
    }
    & $exe   # attach the herdr TUI in this terminal
}

# Print the labels of the live workspaces.
function herd-list {
    if (-not (Ensure-HerdrServer)) { return }
    (& (Get-HerdrExe) workspace list 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue).result.workspaces |
        ForEach-Object { $_.label }
}

# Close a workspace by label (kills everything running in it).
function herd-close {
    param([Parameter(Position = 0, Mandatory)][string]$Name)
    $exe = Get-HerdrExe
    if (-not (Ensure-HerdrServer)) { return }
    $ws = (& $exe workspace list 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue).result.workspaces |
          Where-Object { $_.label -eq $Name }
    if (-not $ws) { Write-Host "herd-close: no workspace labelled '$Name'."; return }
    foreach ($w in @($ws)) { & $exe workspace close $w.workspace_id 2>$null | Out-Null }
    Write-Host "herd-close: closed '$Name'."
}

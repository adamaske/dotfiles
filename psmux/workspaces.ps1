# ──────────────────────────────────────────────────────────────────────────────
# psmux workspace layouts  (tmuxinator-style, declarative)
#
# Dot-sourced from the PowerShell profile. Usage:
#   ws                 list defined workspaces + live sessions
#   ws dev             open/attach the "dev" workspace
#   ws nirwizard       open/attach NIRWizard with its 3-pane layout
#   ws nirwizard -Kill tear the session down
#
# To add a workspace: drop another entry in $PsmuxWorkspaces. Each pane after
# the first splits the *currently focused* pane (i.e. the previous one), so the
# panes read top-to-bottom as the layout is built.
#   Split   = 'h' (side-by-side)  or  'v' (stacked)
#   Percent = size of the NEW pane (optional)
#   Cmd     = command to run in the pane (types it and hits Enter)
#   Type    = text to pre-fill without executing (you press Enter yourself)
# ──────────────────────────────────────────────────────────────────────────────

$global:PsmuxWorkspaces = [ordered]@{
    dev = @{
        Session = 'dev'
        Root    = "$HOME\dev"
        Window  = 'shell'
        Panes   = @(
            @{}                                                   # 1: bare shell
        )
    }
    config = @{
        Session = 'config'
        Root    = "$HOME\.config"
        Window  = 'main'
        Panes   = @(
            @{ Cmd = 'nvim .' }                                   # 1: editor
        )
    }
    nirwizard = @{
        Session = 'NIRWizard'
        Root    = "$HOME\dev\NIRWizard"
        Window  = 'main'
        Panes   = @(
            @{ Cmd = 'nvim .' }                                   # 1: editor   (left)
            @{ Split = 'h'; Percent = 40; Type = 'npx tauri dev' } # 2: dev srv  (top-right, pre-filled)
            @{ Split = 'v'; Percent = 50; Cmd = 'claude' }        # 3: claude   (bottom-right)
        )
    }
    cedanirs = @{
        Session = 'cedanirs'
        Root    = "$HOME\dev\cedanirs"
        Window  = 'main'
        Panes   = @(
            @{ Cmd = 'nvim .' }                                   # 1: editor   (left)
            @{ Split = 'h'; Percent = 40 }                        # 2: shell    (right)
        )
    }
}

# Milliseconds to let a freshly-spawned shell reach its prompt before we type
# into it. Without this, the first keystrokes of e.g. `nvim` can be dropped.
$global:PsmuxSettleMs = 200

function Build-Workspace {
    param([Parameter(Mandatory)][hashtable]$Ws)

    $S      = $Ws.Session
    $W      = $Ws.Window
    $root   = $Ws.Root
    $target = "${S}:${W}"
    $panes  = @($Ws.Panes)

    # new-session is blocked when we're already inside a psmux session. We only
    # ever create *detached* sibling sessions here, so opt out of the guard.
    $prevNest = $env:PSMUX_ALLOW_NESTING
    $env:PSMUX_ALLOW_NESTING = '1'
    try {
        psmux new-session -d -s $S -c $root -n $W
        if ($panes[0].Cmd) {
            Start-Sleep -Milliseconds $global:PsmuxSettleMs
            psmux send-keys -t $target $panes[0].Cmd Enter
        } elseif ($panes[0].Type) {
            Start-Sleep -Milliseconds $global:PsmuxSettleMs
            psmux send-keys -t $target $panes[0].Type
        }

        for ($i = 1; $i -lt $panes.Count; $i++) {
            $p   = $panes[$i]
            $dir = if ($p.Split -eq 'h') { '-h' } else { '-v' }

            $splitArgs = @('split-window', $dir, '-t', $target, '-c', $root)
            if ($p.Percent) { $splitArgs += @('-p', "$($p.Percent)") }
            psmux @splitArgs

            if ($p.Cmd) {
                Start-Sleep -Milliseconds $global:PsmuxSettleMs
                psmux send-keys -t $target $p.Cmd Enter
            } elseif ($p.Type) {
                Start-Sleep -Milliseconds $global:PsmuxSettleMs
                psmux send-keys -t $target $p.Type
            }
        }

        # Focus the first pane (the editor) so you land where you work. Bare %id
        # targets don't stick on a detached session, and pane-base-index may be 0
        # or 1, so query the first pane's actual index and select window.index.
        $firstIdx = psmux list-panes -t $target -F '#{pane_index}' 2>$null | Select-Object -First 1
        if ($null -ne $firstIdx -and $firstIdx -ne '') { psmux select-pane -t "${target}.$firstIdx" }
    }
    finally {
        if ($null -eq $prevNest) { Remove-Item Env:\PSMUX_ALLOW_NESTING -ErrorAction SilentlyContinue }
        else { $env:PSMUX_ALLOW_NESTING = $prevNest }
    }
}

function ws {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ArgumentCompleter({
            param($cmd, $param, $word)
            $global:PsmuxWorkspaces.Keys | Where-Object { $_ -like "$word*" }
        })]
        [string]$Name,

        [switch]$Kill
    )

    if (-not $Name) {
        Write-Host "Defined workspaces:" -ForegroundColor Cyan
        foreach ($k in $global:PsmuxWorkspaces.Keys) {
            "  {0,-12} {1}" -f $k, $global:PsmuxWorkspaces[$k].Root | Write-Host
        }
        Write-Host "`nLive sessions:" -ForegroundColor Cyan
        psmux ls 2>$null
        return
    }

    $key = $Name.ToLower()
    if (-not $global:PsmuxWorkspaces.Contains($key)) {
        Write-Host "Unknown workspace: $Name" -ForegroundColor Red
        Write-Host ("Available: " + ($global:PsmuxWorkspaces.Keys -join ', '))
        return
    }

    $wsDef = $global:PsmuxWorkspaces[$key]
    $S     = $wsDef.Session

    if ($Kill) {
        psmux kill-session -t $S 2>$null
        Write-Host "Killed session: $S"
        return
    }

    # Build only if it isn't already running.
    psmux has-session -t $S 2>$null
    if ($LASTEXITCODE -ne 0) {
        Build-Workspace $wsDef
        # Give the fresh server a moment to finish initializing before we
        # send it commands — without this, source-file can race and be dropped.
        Start-Sleep -Milliseconds 400
    }

    # Point psmux CLI commands at the right server. Without this, commands
    # from outside a session default to a session named "default".
    $env:PSMUX_TARGET_SESSION = $S

    # Apply config (idempotent — safe to call every time).
    psmux source-file "$HOME\.config\psmux\psmux.conf"

    # Propagate into the session's environment so panes inherit it.
    psmux set-environment -t $S PSMUX_TARGET_SESSION $S

    # switch-client when already inside psmux, otherwise attach from the outside.
    if ($env:TMUX -or $env:PSMUX_SESSION) {
        psmux switch-client -t $S
    } else {
        psmux attach-session -t $S
    }
}

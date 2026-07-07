#!/usr/bin/env pwsh
# tmux-style "next-layout" for herdr panes (bound to prefix+space in config.toml).
# Cycles the current tab through tmux's five preset layouts:
#   even-horizontal, even-vertical, main-horizontal, main-vertical, tiled
# The focused pane becomes the big one in the two main-* layouts.
#
# herdr has no native layout command and refuses same-tab `pane move`
# ("reason":"same_tab"), so the rebuild uses the two-hop trick: every pane
# except an anchor hops to a scratch tab, then re-inserts at its target
# position via `pane move --tab <orig> --split --target-pane --ratio`. The
# pane's terminal survives the hop (same terminal_id).
#
# Cycle position is remembered per tab in $env:TEMP\herdr-layout-cycle.json.
# The nvim twin of this lives in nvim/lua/config/layouts.lua (<leader>cl).
#
# Usage: layout-cycle.ps1 [-PaneId <id>] [-Layout <name>]
#   -PaneId  target pane (default: the server-focused pane)
#   -Layout  jump straight to a named layout instead of cycling (testing)
param(
    [string]$PaneId,
    [ValidateSet("", "even-horizontal", "even-vertical", "main-horizontal", "main-vertical", "tiled")]
    [string]$Layout
)

$ErrorActionPreference = "Stop"
$LAYOUTS = @("even-horizontal", "even-vertical", "main-horizontal", "main-vertical", "tiled")
$MAIN_RATIO = 0.55
$StateFile = Join-Path $env:TEMP "herdr-layout-cycle.json"

function Get-HerdrExe {
    $c = Get-Command herdr -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    return "C:\Users\adama\AppData\Local\Programs\Herdr\bin\herdr.exe"
}
$Herdr = Get-HerdrExe

# herdr talks JSON on stdout; transient broken pipes happen on a busy server,
# so retry a couple of times before giving up.
function Invoke-Herdr {
    param([string[]]$HerdrArgs)
    for ($try = 1; $try -le 3; $try++) {
        $raw = & $Herdr @HerdrArgs 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $raw.TrimStart().StartsWith("{")) {
            return ($raw | ConvertFrom-Json).result
        }
        Start-Sleep -Milliseconds 150
    }
    throw "herdr $($HerdrArgs -join ' ') failed: $($raw.Trim())"
}

# ratio semantics (verified on 0.7.1-preview): --ratio is the share the
# EXISTING/TARGET pane keeps; the moved pane gets the rest.
function RatioArg([double]$keep) {
    return [math]::Round([math]::Max(0.05, [math]::Min(0.95, $keep)), 4)
}

function Move-Into {
    param([string]$Pane, [string]$Tab, [string]$Target, [string]$Dir, [double]$Keep, [bool]$Focus)
    $focusFlag = if ($Focus) { "--focus" } else { "--no-focus" }
    $r = Invoke-Herdr @("pane", "move", $Pane, "--tab", $Tab, "--split", $Dir,
        "--target-pane", $Target, "--ratio", (RatioArg $Keep), $focusFlag)
    if (-not $r.move_result.changed) { throw "pane move $Pane refused: $($r.move_result.reason)" }
}

try {
    if (-not $PaneId) {
        $PaneId = (Invoke-Herdr @("pane", "current")).pane.pane_id
    }
    $lay = (Invoke-Herdr @("pane", "layout", "--pane", $PaneId)).layout
    if ($lay.zoomed) {
        Invoke-Herdr @("pane", "zoom", $lay.focused_pane_id, "--off") | Out-Null
        $lay = (Invoke-Herdr @("pane", "layout", "--pane", $PaneId)).layout
    }
    if ($lay.panes.Count -lt 2) { exit 0 }

    $tab = $lay.tab_id
    $ws = $lay.workspace_id
    $focusedPane = $lay.focused_pane_id

    # Which layout is next for this tab?
    $state = @{}
    if (Test-Path $StateFile) {
        try {
            (Get-Content $StateFile -Raw | ConvertFrom-Json).PSObject.Properties |
                ForEach-Object { $state[$_.Name] = [int]$_.Value }
        } catch {}
    }
    $idx = if ($Layout) { $LAYOUTS.IndexOf($Layout) }
           else { (($state[$tab] ?? -1) + 1) % $LAYOUTS.Count }
    $name = $LAYOUTS[$idx]

    # Panes in tmux reading order (top->bottom, left->right); for the main-*
    # layouts the focused pane is promoted to the front and becomes the anchor.
    $ordered = @($lay.panes | Sort-Object { $_.rect.y }, { $_.rect.x } | ForEach-Object { $_.pane_id })
    if ($name -like "main-*") {
        $ordered = @($focusedPane) + @($ordered | Where-Object { $_ -ne $focusedPane })
    }
    $n = $ordered.Count
    $anchor = $ordered[0]
    $others = @($ordered | Select-Object -Skip 1)

    # Hop everything but the anchor out to a scratch tab in this workspace.
    $first = Invoke-Herdr @("pane", "move", $others[0], "--new-tab", "--workspace", $ws,
        "--label", "layout-cycle", "--no-focus")
    $scratch = $first.move_result.pane.tab_id
    foreach ($p in ($others | Select-Object -Skip 1)) {
        Move-Into -Pane $p -Tab $scratch -Target $others[0] -Dir down -Keep 0.5 -Focus $false
    }

    # Re-insert. Every entry: pane, split target, direction, and the share the
    # target keeps (equal chains: inserting item i of a k-chain keeps 1/(k-i+2)).
    $plan = [System.Collections.Generic.List[object]]::new()
    switch -Wildcard ($name) {
        "even-*" {
            $dir = if ($name -eq "even-horizontal") { "right" } else { "down" }
            for ($i = 2; $i -le $n; $i++) {
                $plan.Add(@{ pane = $ordered[$i - 1]; target = $ordered[$i - 2]; dir = $dir; keep = 1 / ($n - $i + 2) })
            }
        }
        "main-*" {
            $dir1 = if ($name -eq "main-vertical") { "right" } else { "down" }
            $dir2 = if ($name -eq "main-vertical") { "down" } else { "right" }
            $plan.Add(@{ pane = $others[0]; target = $anchor; dir = $dir1; keep = $MAIN_RATIO })
            $m = $others.Count
            for ($j = 2; $j -le $m; $j++) {
                $plan.Add(@{ pane = $others[$j - 1]; target = $others[$j - 2]; dir = $dir2; keep = 1 / ($m - $j + 2) })
            }
        }
        "tiled" {
            $cols = [math]::Ceiling([math]::Sqrt($n))
            $rows = [math]::Ceiling($n / $cols)
            for ($r = 2; $r -le $rows; $r++) {   # row leaders first, full width
                $plan.Add(@{ pane = $ordered[($r - 1) * $cols]; target = $ordered[($r - 2) * $cols]; dir = "down"; keep = 1 / ($rows - $r + 2) })
            }
            for ($r = 1; $r -le $rows; $r++) {   # then fill each row rightwards
                $rowLen = [math]::Min($cols, $n - ($r - 1) * $cols)
                for ($k = 2; $k -le $rowLen; $k++) {
                    $i = ($r - 1) * $cols + $k - 1
                    $plan.Add(@{ pane = $ordered[$i]; target = $ordered[$i - 1]; dir = "right"; keep = 1 / ($rowLen - $k + 2) })
                }
            }
        }
    }
    foreach ($step in $plan) {
        Move-Into -Pane $step.pane -Tab $tab -Target $step.target -Dir $step.dir `
            -Keep $step.keep -Focus ($step.pane -eq $focusedPane)
    }

    # The scratch tab should be empty now; close it if herdr left it behind.
    # Never close it with panes still inside - that would kill their terminals.
    $left = @((Invoke-Herdr @("pane", "list", "--workspace", $ws)).panes |
        Where-Object { $_.tab_id -eq $scratch })
    if ($left.Count -eq 0) {
        try { Invoke-Herdr @("tab", "close", $scratch) | Out-Null } catch {}
    }

    $state[$tab] = $idx
    $state | ConvertTo-Json | Set-Content $StateFile
} catch {
    & $Herdr notification show "Layout cycle failed" --body "$_" 2>$null
    exit 1
}

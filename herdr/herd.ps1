# =============================================================================
#  herd.ps1 — herdr workspace launcher (the herdr analog of `ws`/psmux).
#  Dot-sourced from the PowerShell profile so `herd <name>` is always available.
#
#  Each workspace: pane1 = nvim ., split right for claude / dev tooling (panes
#  persist in herdr's session.json, so you only create each one once).
#
#  Usage:  herd                 -> list herdr workspaces
#          herd dev             -> ~/dev                 (nvim + shell)
#          herd config          -> ~/.config            (nvim + claude)
#          herd nirwizard       -> ~/dev/NIRWizard       (nvim + claude + tauri dev)
#          herd cedanirs        -> ~/dev/cedanirs        (nvim + pytest + claude)
#          herd askeengineering -> ~/dev/askeengineering (nvim + claude)
#          Herd-Init            -> create all of the above (no attach)
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

# label -> dir + the commands for the right-side panes (top-down)
$script:HerdSpecs = [ordered]@{
    'dev'             = @{ label = 'dev';             dir = "$HOME\dev";                 cmds = @() }
    'config'          = @{ label = 'config';          dir = "$HOME\.config";             cmds = @('claude --resume') }
    'nirwizard'       = @{ label = 'NIRWizard';       dir = "$HOME\dev\NIRWizard";       cmds = @('claude --resume', 'npx tauri dev') }
    'cedanirs'        = @{ label = 'cedanirs';        dir = "$HOME\dev\cedanirs";        cmds = @('pytest', 'claude --resume') }
    'askeengineering' = @{ label = 'askeengineering'; dir = "$HOME\dev\askeengineering"; cmds = @('claude --resume') }
}

# Create a workspace + its panes if a workspace with that label doesn't exist.
# Returns the workspace id, or $null on unknown name / failure. Does NOT attach.
function New-HerdWorkspace {
    param([Parameter(Mandatory)][string]$Name)
    $exe = Get-HerdrExe
    $spec = $script:HerdSpecs[$Name.ToLower()]
    if (-not $spec) {
        Write-Host "Unknown workspace: $Name"
        Write-Host "Available: $(($script:HerdSpecs.Keys) -join ', ')"
        return $null
    }
    if (-not (Ensure-HerdrServer)) { return $null }

    $dir = if (Test-Path $spec.dir) { $spec.dir } else { "$HOME\dev" }

    # idempotent: reuse an existing workspace with this label
    $list = (& $exe workspace list 2>$null) | ConvertFrom-Json -ErrorAction SilentlyContinue
    $existing = $list.result.workspaces | Where-Object { $_.label -eq $spec.label }
    if ($existing) { return $existing.workspace_id }

    $ws  = (& $exe workspace create --cwd $dir --label $spec.label --no-focus 2>$null) |
           ConvertFrom-Json -ErrorAction SilentlyContinue
    $wid = $ws.result.workspace.workspace_id
    $p1  = $ws.result.root_pane.pane_id
    if (-not $p1) {
        Write-Host "herd: failed to create workspace '$($spec.label)' (is the herdr server up?)." -ForegroundColor Yellow
        return $null
    }

    & $exe pane send-text $p1 "nvim ." | Out-Null
    & $exe pane send-keys $p1 enter    | Out-Null

    # first extra pane splits right (35%), the rest stack downward
    $target = $p1; $dir2 = 'right'; $ratio = 0.35
    foreach ($cmd in $spec.cmds) {
        $np = ((& $exe pane split $target --direction $dir2 --ratio $ratio --no-focus 2>$null) |
               ConvertFrom-Json -ErrorAction SilentlyContinue).result.pane.pane_id
        if (-not $np) { continue }
        & $exe pane send-text $np $cmd | Out-Null
        & $exe pane send-keys $np enter | Out-Null
        $target = $np; $dir2 = 'down'; $ratio = 0.5
    }
    return $wid
}

# Create (if needed), focus, and attach to a workspace.
function herd {
    param([Parameter(Position = 0)][string]$Name)
    $exe = Get-HerdrExe
    if (-not (Ensure-HerdrServer)) { return }
    if (-not $Name) {
        (& $exe workspace list 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue).result.workspaces |
            ForEach-Object { $_.label }
        return
    }
    $wid = New-HerdWorkspace $Name
    if (-not $wid) { return }
    & $exe workspace focus $wid 2>$null | Out-Null
    & $exe   # attach the herdr TUI in this terminal
}

# Pre-create all workspaces (they persist; run once). Does not attach.
function Herd-Init {
    if (-not (Ensure-HerdrServer)) { return }
    foreach ($n in $script:HerdSpecs.Keys) { New-HerdWorkspace $n | Out-Null }
    (& (Get-HerdrExe) workspace list 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue).result.workspaces |
        ForEach-Object { $_.label }
}

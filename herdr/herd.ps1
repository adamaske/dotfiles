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
#          herd sys             -> ~   on-demand monitors as 3 tabs: proc (pstop),
#                                       cpu (btop), gpu (nvitop). NOT auto-started.
#          herd-close sys       -> tear down sys (stops btop/nvitop — frees the dGPU)
#          Herd-Init            -> create all non-ondemand workspaces (no attach)
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
    # sys: system-monitor scratch workspace. On-demand only (ondemand = skip in
    # Herd-Init) because nvitop polls the NVIDIA dGPU continuously, which keeps the
    # RTX 3060 awake and drains laptop battery — so we never leave it running at
    # login. Custom tabbed layout via Build-HerdSys (build = 'sys').
    'sys'             = @{ label = 'sys';             dir = "$HOME";                     ondemand = $true; build = 'sys' }
}

# Build the `sys` monitor workspace as three full-screen tabs — one per monitor,
# so each gets the whole terminal (btop/nvitop have minimum size requirements that
# a split view can't guarantee, and nvitop exits outright when too small):
#   Tab 1 "proc": pstop  (task-manager replacement)
#   Tab 2 "cpu":  btop   (CPU / mem / disk / net)
#   Tab 3 "gpu":  nvitop (NVIDIA GPU)
# Returns the workspace id, or $null on failure. The proc tab is left focused.
function Build-HerdSys {
    param([Parameter(Mandatory)]$spec)
    $exe = Get-HerdrExe

    # Tab 1 (the workspace root tab) -> pstop
    $ws  = (& $exe workspace create --cwd $HOME --label $spec.label --no-focus 2>$null) |
           ConvertFrom-Json -ErrorAction SilentlyContinue
    $wid   = $ws.result.workspace.workspace_id
    $t1    = $ws.result.tab.tab_id
    $pProc = $ws.result.root_pane.pane_id
    if (-not $pProc) {
        Write-Host "herd: failed to create 'sys' workspace (is the herdr server up?)." -ForegroundColor Yellow
        return $null
    }
    if ($t1) { & $exe tab rename $t1 'proc' 2>$null | Out-Null }
    & $exe pane send-text $pProc 'pstop' | Out-Null
    & $exe pane send-keys $pProc enter   | Out-Null

    # Tabs 2 & 3 -> btop, nvitop (label -> command)
    foreach ($t in @(@{ label = 'cpu'; cmd = 'btop' }, @{ label = 'gpu'; cmd = 'nvitop' })) {
        $tab = (& $exe tab create --workspace $wid --cwd $HOME --label $t.label --no-focus 2>$null) |
               ConvertFrom-Json -ErrorAction SilentlyContinue
        $p = $tab.result.root_pane.pane_id
        if ($p) {
            & $exe pane send-text $p $t.cmd | Out-Null
            & $exe pane send-keys $p enter  | Out-Null
        }
    }

    # leave the process tab focused
    if ($t1) { & $exe tab focus $t1 2>$null | Out-Null }
    return $wid
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

    # workspaces with a custom builder (e.g. sys: tabbed monitor layout)
    if ($spec.build -eq 'sys') { return (Build-HerdSys $spec) }

    $ws  = (& $exe workspace create --cwd $dir --label $spec.label --no-focus 2>$null) |
           ConvertFrom-Json -ErrorAction SilentlyContinue
    $wid = $ws.result.workspace.workspace_id
    $p1  = $ws.result.root_pane.pane_id
    if (-not $p1) {
        Write-Host "herd: failed to create workspace '$($spec.label)' (is the herdr server up?)." -ForegroundColor Yellow
        return $null
    }

    $rootCmd = if ($spec.root) { $spec.root } else { 'nvim .' }
    & $exe pane send-text $p1 $rootCmd | Out-Null
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
# Skips `ondemand` specs (e.g. sys) so heavy monitors never run at login — use
# `herd sys` to spin those up when you actually want them.
function Herd-Init {
    if (-not (Ensure-HerdrServer)) { return }
    foreach ($n in $script:HerdSpecs.Keys) {
        if ($script:HerdSpecs[$n].ondemand) { continue }
        New-HerdWorkspace $n | Out-Null
    }
    (& (Get-HerdrExe) workspace list 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue).result.workspaces |
        ForEach-Object { $_.label }
}

# Close a workspace by label (kills everything running in it — the clean way to
# stop the sys monitors when you're done: `herd-close sys`).
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

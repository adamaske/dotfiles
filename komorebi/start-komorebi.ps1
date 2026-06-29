# =============================================================================
#  start-komorebi.ps1  —  start the whole desktop shell (mirrors Hyprland autostart)
#  Starts:  komorebi (tiling WM)  +  AutoHotkey hotkeys (komorebi.ahk)  +  yasb bar
#  Run at login via a Startup-folder shortcut, or manually any time.
# =============================================================================

$ErrorActionPreference = 'SilentlyContinue'

$cfg = $env:KOMOREBI_CONFIG_HOME
if (-not $cfg) { $cfg = "$HOME\.config\komorebi" }

# 1) komorebi window manager. NOTE: no '--bar' flag (we use yasb, not komorebi-bar).
#    Pass --config explicitly; do NOT write '--bar:$false' (PowerShell turns that
#    into the invalid literal arg '--bar:False' and komorebi fails to start).
if (-not (Get-Process komorebi -ErrorAction SilentlyContinue)) {
    komorebic start --config "$cfg\komorebi.json"
    Start-Sleep -Seconds 2
}

# 2) AutoHotkey hotkey daemon (komorebi.ahk). Launch the v2 exe directly so it
#    works even if AutoHotkey isn't on PATH.
$ahk = @(
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey.exe",
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($ahk -and -not (Get-Process AutoHotkey* -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $ahk })) {
    Start-Process $ahk -ArgumentList "`"$cfg\komorebi.ahk`""
}

# 3) yasb status bar (replaces waybar)
if (-not (Get-Process yasb -ErrorAction SilentlyContinue)) {
    if (Get-Command yasbc -ErrorAction SilentlyContinue) { Start-Process yasbc -ArgumentList 'start' }
    elseif (Test-Path "$env:ProgramFiles\YASB\yasb.exe") { Start-Process "$env:ProgramFiles\YASB\yasb.exe" }
}

# 4) Pre-warm herdr: start the headless server (detached) + (re)populate workspaces.
#    On reboot herdr restores only the workspace SHAPE (empty shells in the right
#    dirs); Herd-Init re-runs the pane commands (nvim/claude/pytest/tauri).
$herdrExe = if (Get-Command herdr -ErrorAction SilentlyContinue) { 'herdr' }
            else { 'C:\Users\adama\AppData\Local\Programs\Herdr\bin\herdr.exe' }

$serverUp = $false
try { $serverUp = ((& $herdrExe status 2>$null) -match 'status:\s*running') } catch {}
if (-not $serverUp) {
    Start-Process -FilePath $herdrExe -ArgumentList 'server' -WindowStyle Hidden
    for ($i = 0; $i -lt 50; $i++) {                      # wait up to ~10s until reachable
        if ((& $herdrExe status 2>$null) -match 'status:\s*running') { break }
        Start-Sleep -Milliseconds 200
    }
}

$herdScript = "$HOME\.config\herdr\herd.ps1"
if (Test-Path $herdScript) {
    . $herdScript
    Herd-Init | Out-Null
}

Write-Host "komorebi + AHK hotkeys + yasb + herdr server & workspaces started."

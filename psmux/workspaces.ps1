# =============================================================================
#  workspaces.ps1  —  psmux dev-session launcher (mirrors tmux/sessions.sh)
#  Dot-sourced from the PowerShell profile so `ws <name>` is always available,
#  and from start-komorebi.ps1 so `Start-AllWorkspaces` pre-warms them at login.
#
#  Layout per session: pane1 = nvim ., a split for claude / dev server,
#  pane1 grown to 65% width — same as the Arch tmux sessions.
#
#  Usage:  ws                 -> list sessions
#          ws config          -> ~/.config        (nvim + claude)
#          ws nirwizard       -> ~/dev/NIRWizard   (nvim + claude + `npx tauri dev`)
#          ws cedanirs        -> ~/dev/cedanirs    (nvim + pytest + claude)
#          ws askeengineering -> ~/dev/askeengineering (nvim + claude)
#          Start-AllWorkspaces -> create all four detached (login pre-warm)
# =============================================================================

# Create a session (detached) if it doesn't already exist. Returns the real
# session name, or $null for an unknown workspace. Does NOT attach.
function New-WsSession {
    param([Parameter(Mandatory)][string]$Name)

    function Resolve-Dir([string]$p) { if (Test-Path $p) { $p } else { "$HOME\dev" } }

    switch ($Name.ToLower()) {
        'config' {
            $session = 'config'; $dir = "$HOME\.config"
            psmux has-session -t $session 2>$null
            if ($LASTEXITCODE -ne 0) {
                psmux new-session -d -s $session -c $dir
                psmux send-keys   -t "${session}:1.1" "nvim ." Enter
                psmux split-window -h -t "${session}:1" -c $dir
                psmux split-window -v -t "${session}:1.2" -c $dir
                psmux send-keys   -t "${session}:1.3" "claude --resume" Enter
                psmux select-pane -t "${session}:1.1"
                psmux resize-pane -t "${session}:1.1" -x "65%"
            }
            return $session
        }
        'nirwizard' {
            $session = 'NIRWizard'; $dir = Resolve-Dir "$HOME\dev\NIRWizard"
            psmux has-session -t $session 2>$null
            if ($LASTEXITCODE -ne 0) {
                psmux new-session -d -s $session -c $dir
                psmux send-keys   -t "${session}:1.1" "nvim ." Enter
                psmux split-window -h -t "${session}:1" -c $dir
                psmux send-keys   -t "${session}:1.2" "claude --resume" Enter
                psmux split-window -v -t "${session}:1.2" -c $dir
                psmux send-keys   -t "${session}:1.3" "npx tauri dev"
                psmux select-pane -t "${session}:1.1"
                psmux resize-pane -t "${session}:1.1" -x "65%"
            }
            return $session
        }
        'cedanirs' {
            $session = 'cedanirs'; $dir = Resolve-Dir "$HOME\dev\cedanirs"
            psmux has-session -t $session 2>$null
            if ($LASTEXITCODE -ne 0) {
                psmux new-session -d -s $session -c $dir
                psmux send-keys   -t "${session}:1.1" "nvim ." Enter
                psmux split-window -h -t "${session}:1" -c $dir
                psmux send-keys   -t "${session}:1.2" "pytest" Enter
                psmux split-window -v -t "${session}:1.2" -c $dir
                psmux send-keys   -t "${session}:1.3" "claude --resume" Enter
                psmux select-pane -t "${session}:1.1"
                psmux resize-pane -t "${session}:1.1" -x "65%"
            }
            return $session
        }
        'askeengineering' {
            $session = 'askeengineering'; $dir = Resolve-Dir "$HOME\dev\askeengineering"
            psmux has-session -t $session 2>$null
            if ($LASTEXITCODE -ne 0) {
                psmux new-session -d -s $session -c $dir
                psmux send-keys   -t "${session}:1.1" "nvim ." Enter
                psmux split-window -h -t "${session}:1" -c $dir
                psmux send-keys   -t "${session}:1.2" "claude --resume" Enter
                psmux select-pane -t "${session}:1.1"
                psmux resize-pane -t "${session}:1.1" -x "65%"
            }
            return $session
        }
        'dev' {
            $session = 'dev'; $dir = Resolve-Dir "$HOME\dev"
            psmux has-session -t $session 2>$null
            if ($LASTEXITCODE -ne 0) {
                psmux new-session -d -s $session -c $dir
                psmux send-keys   -t "${session}:1.1" "nvim ." Enter
                psmux split-window -h -t "${session}:1" -c $dir
                psmux select-pane -t "${session}:1.1"
                psmux resize-pane -t "${session}:1.1" -x "65%"
            }
            return $session
        }
        default {
            Write-Host "Unknown workspace: $Name"
            Write-Host "Available: dev, config, nirwizard, cedanirs, askeengineering"
            return $null
        }
    }
}

# Attach (or switch) to a workspace, creating it on demand.
function ws {
    param([Parameter(Position = 0)][string]$Name)

    if (-not $Name) { psmux ls; return }

    $session = New-WsSession $Name
    if (-not $session) { return }

    if ($env:TMUX) { psmux switch-client -t $session }
    else           { psmux attach-session -t $session }
}

# Create all four sessions detached — mirrors sessions.sh start_sessions().
function Start-AllWorkspaces {
    foreach ($n in 'config', 'nirwizard', 'cedanirs', 'askeengineering') {
        New-WsSession $n | Out-Null
    }
    psmux ls
}

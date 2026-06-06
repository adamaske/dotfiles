function ws {
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    if (-not $Name) {
        psmux ls
        return
    }

    $session = $null

    switch ($Name.ToLower()) {
        'dev' {
            $session = 'dev'
            psmux has-session -t $session 2>$null
            if ($LASTEXITCODE -ne 0) {
                psmux new-session -d -s $session -c "$HOME\dev" -n shell
            }
        }
        'nirwizard' {
            $session = 'NIRWizard'
            psmux has-session -t $session 2>$null
            if ($LASTEXITCODE -ne 0) {
                psmux new-session -d -s $session -c "$HOME\dev\NIRWizard" -n shell
                psmux new-window  -t $session -n editor -c "$HOME\dev\NIRWizard"
                psmux send-keys   -t "${session}:editor" "nvim ." Enter
                psmux select-window -t "${session}:shell"
            }
        }
        'ceda' {
            $session = 'Ceda'
            psmux has-session -t $session 2>$null
            if ($LASTEXITCODE -ne 0) {
                # TODO: full Ceda workspace setup
                psmux new-session -d -s $session -c "$HOME\dev" -n shell
            }
        }
        default {
            Write-Host "Unknown workspace: $Name"
            Write-Host "Available: dev, nirwizard, ceda"
            return
        }
    }

    if ($env:TMUX) {
        psmux switch-client -t $session
    } else {
        psmux attach-session -t $session
    }
}

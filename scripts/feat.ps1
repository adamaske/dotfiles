# =============================================================================
#  feat.ps1 — one-command treehouse feature worktrees for Claude Code.
#  Dot-sourced from the PowerShell profile so `feat` is always available.
#
#    feat <name>        lease a warm worktree, branch feat/<name>, launch Claude
#    feat-ship [-Base b] push the branch, open a PR, and return the worktree
#    feat-done [path]   return the current (or given) worktree to the pool
#    feat-cancel [path] abandon: discard changes, return the worktree, drop the branch
#    feat-list          show active worktrees (git branches + treehouse pool state)
#
#  The loop (run from inside a treehouse-tracked repo, e.g. ~/dev/NIRWizard):
#    feat forward-cache            # -> warm isolated worktree, on branch feat/forward-cache, Claude up
#    ...dev the feature in Claude (commit as you go)...
#    feat-ship -Base pre-refactor  # push + PR + return, all in one
#
#  Or step-by-step instead of feat-ship:
#    git push -u origin feat/forward-cache ; gh pr create --fill --base pre-refactor ; feat-done
#
#  Notes:
#    - treehouse worktrees start on a DETACHED HEAD; `feat` runs `git checkout -b` for you.
#    - `feat` leases from whatever repo you're standing in (its treehouse.toml pool).
#    - Pass a name containing '/' to use it verbatim as the branch (e.g. `feat fix/hdf5`).
# =============================================================================

function feat {
    param([Parameter(Mandatory, Position = 0)][string]$Name)

    if (-not (Get-Command treehouse -ErrorAction SilentlyContinue)) {
        Write-Host "feat: treehouse is not on PATH." -ForegroundColor Yellow; return
    }
    # Must be inside a git repo — treehouse leases from THIS repo's pool.
    $repo = git rev-parse --show-toplevel 2>$null
    if (-not $repo) {
        Write-Host "feat: run this from inside a git repo (a treehouse-tracked one)." -ForegroundColor Yellow; return
    }
    # Refuse to lease from inside a linked worktree: the worktree's checked-out
    # treehouse.toml would spawn a pool nested under it, and nested pools blow
    # past the Windows 260-char path limit (Cargo/MSVC builds fail).
    $gitCommon = (git rev-parse --git-common-dir 2>$null) -replace '/', '\'
    $gitDir    = (git rev-parse --git-dir 2>$null)        -replace '/', '\'
    if ($gitCommon -and $gitDir -and $gitCommon -ne $gitDir) {
        $main = Split-Path $gitCommon -Parent
        Write-Host "feat: you're inside a worktree — lease from the main repo instead:" -ForegroundColor Yellow
        Write-Host "      cd $main ; feat $Name" -ForegroundColor Yellow
        return
    }

    $branch = if ($Name -match '/') { $Name } else { "feat/$Name" }
    $label  = 'feat-' + ($branch -replace '[\\/ ]', '-')

    # 1. treehouse: durable lease -> warm, isolated worktree path.
    #    --lease prints ONLY the path to stdout; all banners go to stderr (2>$null).
    $wt = (treehouse get --lease --lease-holder $label 2>$null |
           Where-Object { $_ -and $_.Trim() } | Select-Object -Last 1)
    if ($wt) { $wt = $wt.Trim() }
    if (-not $wt -or -not (Test-Path $wt)) {
        Write-Host "feat: treehouse lease failed (pool full? try 'treehouse status')." -ForegroundColor Yellow; return
    }

    # 2. Move into it and branch off the detached HEAD.
    Set-Location $wt
    git checkout -b $branch 2>$null
    if ($LASTEXITCODE -ne 0) { git checkout $branch }   # branch already exists -> reuse it

    Write-Host "feat: $branch  @  $wt" -ForegroundColor Green
    Write-Host "      finish with:  feat-ship   (push + PR + return)" -ForegroundColor DarkGray

    # 3. Hand off to Claude. You're left in the worktree (on the branch) when it exits.
    claude
}

function feat-ship {
    param(
        [string]$Base,        # PR base branch (default: the repo's default branch)
        [switch]$Draft,       # open the PR as a draft
        [switch]$Keep,        # keep the worktree (skip the return) — e.g. to iterate on review
        [switch]$AllowDirty,  # push even with uncommitted changes (they will NOT be in the PR)
        [switch]$Force        # force the worktree return (clean/reset without prompting)
    )

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host "feat-ship: gh (GitHub CLI) is not on PATH." -ForegroundColor Yellow; return
    }
    $wt = git rev-parse --show-toplevel 2>$null
    if (-not $wt) { Write-Host "feat-ship: not inside a git repo." -ForegroundColor Yellow; return }

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch -or $branch -eq 'HEAD') {
        Write-Host "feat-ship: detached HEAD — check out a feature branch first." -ForegroundColor Yellow; return
    }

    # Refuse to ship a dirty tree — uncommitted work would silently miss the PR.
    if (-not $AllowDirty -and (git status --porcelain 2>$null)) {
        Write-Host "feat-ship: uncommitted changes present — commit them first (or pass -AllowDirty)." -ForegroundColor Yellow
        return
    }

    # 1. Push the branch and set upstream.
    Write-Host "feat-ship: pushing $branch ..." -ForegroundColor Cyan
    git push -u origin $branch
    if ($LASTEXITCODE -ne 0) { Write-Host "feat-ship: push failed." -ForegroundColor Yellow; return }

    # 2. Open the PR (or reuse an existing one for this branch).
    $prArgs = @('pr', 'create', '--fill')
    if ($Base)  { $prArgs += @('--base', $Base) }
    if ($Draft) { $prArgs += '--draft' }
    $url = gh @prArgs 2>$null | Select-Object -Last 1
    if (-not $url) { $url = gh pr view --json url -q .url 2>$null }   # a PR may already exist
    if ($url) { Write-Host "feat-ship: PR -> $url" -ForegroundColor Green }
    else      { Write-Host "feat-ship: pushed, but could not open/find a PR (open it manually)." -ForegroundColor Yellow }

    # 3. Return the worktree to the pool (unless -Keep, e.g. to address review in the warm tree).
    if ($Keep) {
        Write-Host "feat-ship: keeping worktree $wt (run 'feat-done' when done)." -ForegroundColor DarkGray
        return
    }
    if ($Force) { feat-done $wt -Force } else { feat-done $wt }
}

function feat-done {
    param([Parameter(Position = 0)][string]$Path, [switch]$Force)

    if (-not (Get-Command treehouse -ErrorAction SilentlyContinue)) {
        Write-Host "feat-done: treehouse is not on PATH." -ForegroundColor Yellow; return
    }
    if ($Path -and -not (Test-Path $Path)) {
        Write-Host "feat-done: no such path: $Path" -ForegroundColor Yellow; return
    }
    $wt = if ($Path) { (Resolve-Path $Path).Path } else { (Get-Location).Path }

    # Step OUT of the worktree we're about to reset: cd to the repo's main worktree.
    $main = ((git -C $wt worktree list --porcelain 2>$null) |
             Where-Object { $_ -like 'worktree *' } | Select-Object -First 1) -replace '^worktree ', ''
    if ($main -and (Test-Path $main)) { Set-Location $main }

    # `treehouse return` terminates lingering processes and returns to the pool;
    # -Force also cleans/resets any uncommitted leftovers without prompting.
    $thArgs = @('return', $wt)
    if ($Force) { $thArgs += '--force' }
    treehouse @thArgs
    Write-Host "feat-done: returned $wt to the pool (branch & PR untouched)." -ForegroundColor Green
}

function feat-cancel {
    param(
        [Parameter(Position = 0)][string]$Path,  # worktree to cancel (default: current)
        [switch]$Remote,      # ALSO close the PR and delete the pushed branch on origin
        [switch]$KeepBranch   # keep the local branch ref (default: delete it)
    )

    if (-not (Get-Command treehouse -ErrorAction SilentlyContinue)) {
        Write-Host "feat-cancel: treehouse is not on PATH." -ForegroundColor Yellow; return
    }
    if ($Path -and -not (Test-Path $Path)) {
        Write-Host "feat-cancel: no such path: $Path" -ForegroundColor Yellow; return
    }
    $wt = if ($Path) { (Resolve-Path $Path).Path } else { (Get-Location).Path }

    # Identify the branch and the repo's default branch (never cancel the default).
    $branch = git -C $wt rev-parse --abbrev-ref HEAD 2>$null
    if ($branch -eq 'HEAD') { $branch = $null }   # detached — nothing to drop
    $def = (git -C $wt symbolic-ref --short refs/remotes/origin/HEAD 2>$null) -replace '^origin/', ''
    if ($branch -and $def -and $branch -eq $def) {
        Write-Host "feat-cancel: on the default branch ($branch), not a feature branch — aborting." -ForegroundColor Yellow
        return
    }

    # Step OUT of the worktree we're about to reset: cd to the repo's main worktree.
    $main = ((git -C $wt worktree list --porcelain 2>$null) |
             Where-Object { $_ -like 'worktree *' } | Select-Object -First 1) -replace '^worktree ', ''
    if ($main -and (Test-Path $main)) { Set-Location $main }

    # 1. Force-return: discard uncommitted work, reset, hand the worktree back to the pool.
    treehouse return $wt --force

    # 2. Optionally tear down the pushed side (outward-facing — opt in with -Remote).
    if ($Remote -and $branch) {
        gh pr close $branch --delete-branch 2>$null       # closes PR + deletes origin branch
        if ($LASTEXITCODE -ne 0) { git push origin --delete $branch 2>$null }  # no PR: just the branch
        Write-Host "feat-cancel: closed PR / deleted origin/$branch." -ForegroundColor Green
    }

    # 3. Drop the local branch ref (safe now — the worktree is detached).
    if ($branch -and -not $KeepBranch) {
        git branch -D $branch 2>$null | Out-Null
    }

    $note = if ($branch) { "branch $branch" } else { "(detached, no branch)" }
    Write-Host "feat-cancel: cancelled $note, returned $wt to the pool." -ForegroundColor Green
}

function feat-list {
    param([switch]$Raw)   # -Raw: only treehouse's own pool status (skip the git view)

    if (-not (Get-Command treehouse -ErrorAction SilentlyContinue)) {
        Write-Host "feat-list: treehouse is not on PATH." -ForegroundColor Yellow; return
    }
    if (-not (git rev-parse --show-toplevel 2>$null)) {
        Write-Host "feat-list: run this from inside a git repo." -ForegroundColor Yellow; return
    }

    # git view: every worktree and the branch it's checked out on (stable output).
    if (-not $Raw) {
        Write-Host "worktrees (branch each is on):" -ForegroundColor Cyan
        git worktree list
        Write-Host ""
    }
    # treehouse view: pool slots, lease state, and live processes (the source of truth).
    Write-Host "treehouse pool (lease state + live processes):" -ForegroundColor Cyan
    treehouse status
}

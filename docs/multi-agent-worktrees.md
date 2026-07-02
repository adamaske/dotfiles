# Running Multiple Agents on One Repo with Treehouse + Pull Requests

The problem with pointing several agents at a single working directory is that they share one set of files and one `HEAD`.
Agent A stages a change, Agent B runs a build, Agent A commits B's half-finished edits, and everyone stomps on `git checkout`.

Plain `git worktree` solves the isolation part but leaves you doing the bookkeeping: naming directories, tracking which is free, cleaning up stale ones, and rebuilding dependencies from scratch in every new checkout.
[Treehouse](https://github.com/kunchenguid/treehouse) automates exactly that layer.

## What treehouse gives you over raw `git worktree`

Treehouse maintains a **pool of reusable worktrees per repository** under `~/.treehouse/` (configurable).
Instead of creating and deleting worktrees by hand, you *acquire* one from the pool and *return* it when done.

- **Instant isolation, no setup churn** - `treehouse get` hands you a clean worktree immediately; no `worktree add`, no naming, no path juggling.
- **Persistent build state** - dependencies, `node_modules`, and build caches survive across sessions because the same physical worktrees are reused. Successive agent runs start warm instead of cold.
- **Automatic conflict avoidance** - it tracks which worktrees are in use (process-based detection) and never hands the same one to two agents.
- **Detached HEAD by default** - each worktree resets to whichever of the local/remote default branch is further ahead, so there are no branch-name collisions between the pool and your feature branches.
- **Durable leases** - an agent can hold a worktree as a persistent home without keeping a live process inside it.
- **No daemon** - it is just a CLI operating on git state; nothing runs in the background.

## Core commands

```
treehouse get [--lease] [--lease-holder <label>]   # acquire a worktree
treehouse status                                    # show pool state
treehouse return [path] [--force]                   # release back to the pool
treehouse prune [--yes] [--all] [--prune-orphans]   # remove stale, idle worktrees
treehouse destroy <path|pool> [--yes] ...           # deliberately remove specific ones
```

- `treehouse get` (no flags) fetches origin, picks a free/clean worktree (or creates one), and drops you into a **subshell** inside it. Exit the shell and it returns to the pool.
- `treehouse get --lease` marks a worktree leased in treehouse's persistent state and **prints only its absolute path** to stdout - no subshell. Leased worktrees are never handed out by a later `get` and never removed by `prune` until you `treehouse return <path>`.

The lease form is the important one for agents: you point the agent at the printed path as its working directory, and the worktree stays reserved for that agent across many commands and sessions.

## Configuration

Two config files, repo-level taking precedence:

- Repo: `treehouse.toml` in the repository root
- User: `~/.config/treehouse/config.toml`

```toml
max_trees = 16              # pool size limit (upper bound on concurrent agents)
root = "$HOME/worktrees"    # optional custom worktree root
```

Set `max_trees` at or above the number of agents you intend to run at once.
On this machine that config lives at `~/.config/treehouse/config.toml`, which is inside this very repo - so the setting is version-controlled and mirrors across your two PCs automatically.

## The multi-agent + PR workflow

### 1. Give each agent a leased worktree

```powershell
# Reserve one isolated worktree per agent, labeled so `status` is readable
$auth   = treehouse get --lease --lease-holder agent-auth
$search = treehouse get --lease --lease-holder agent-search
$flaky  = treehouse get --lease --lease-holder agent-flaky
```

Each variable now holds an absolute path.
Launch each agent with its path as the working directory. The agents cannot see or corrupt each other's files, and each starts with warm build state.

You can also set `$TREEHOUSE_LEASE_HOLDER` in the environment instead of passing `--lease-holder`.

### 2. Each agent branches off detached HEAD

The worktree starts in detached HEAD at the tip of the default branch, so the first thing an agent does is create its own branch:

```powershell
git checkout -b feat/auth
# ... implement, commit in small focused steps ...
git push -u origin feat/auth
```

Because every worktree resets to the *latest* default branch on acquisition, all agents diverge from a common, known-good base.

### 3. Open a pull request per branch

```powershell
gh pr create --fill --base main
```

One feature = one branch = one PR. Keep each small enough to review in a single sitting.

### 4. Integrate through the PR gate

1. **CI runs on every PR** - tests, lint, build must pass before merge. This is your safety net when an agent, not you, wrote the code.
2. **Review before merge** - run `/code-review` on the diff or dispatch a reviewer agent. Never merge an agent's work unread.
3. **Merge order matters** - land the most foundational branch first, then rebase the trailing branches on the new `main` so they integrate against reality, not a stale base:
   ```powershell
   git fetch origin
   git rebase origin/main
   ```
4. **Squash-merge** to collapse an agent's noisy commit stream into one meaningful commit on `main`.

### 5. Return worktrees to the pool

```powershell
treehouse return $auth
treehouse return $search
treehouse return $flaky
```

The branches persist in the remote (and in your PRs); the worktrees reset to detached HEAD and become available for the next agents, **keeping their build cache**.
Run `treehouse prune` occasionally to clear genuinely stale, idle worktrees, and `treehouse status` any time to see what is leased or in use.

## Rules that keep parallel agents from colliding

1. **One branch, one agent, one concern.** If two tasks must edit the same core module, they are not independent - run them sequentially.
2. **No shared mutable state outside the repo.** A single dev database or a fixed port defeats the isolation. Give each agent its own port/db, or the parallelism is an illusion. (Treehouse isolates *files*, not services.)
3. **Small, frequent commits.** Smaller diffs review faster and conflict less.
4. **Rebase, don't merge, to catch up** when `main` moves under a branch.
5. **Conflicts are a signal you over-parallelized.** Resolve them in the trailing PR at rebase time, never by force-pushing over `main`. Frequent conflicts mean you should re-partition the tasks.

## A realistic loop

```
1. Break the feature into genuinely independent tasks.
2. treehouse get --lease  ->  one worktree path per task.
3. Point one agent at each path.
4. Each agent: branch -> implement -> commit -> push -> open PR.
5. CI validates each PR in isolation.
6. Review, then merge PRs one at a time, rebasing the rest.
7. treehouse return each worktree; prune periodically.
```

## When NOT to parallelize

- Tasks that touch the same files or the same abstraction - do them in sequence.
- Work that depends on another task's output - that is a pipeline, not a fan-out.
- Anything where integration cost (conflict resolution + review) exceeds the time saved.

Treehouse removes the *mechanical* cost of isolation, but it does not make overlapping tasks independent.
Fewer agents on cleaner boundaries still beats many agents fighting over the same code.

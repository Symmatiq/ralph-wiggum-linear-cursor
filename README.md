# ralph-wiggum-linear-cursor

Linear-first parallel runner for Cursor (Phase A doc: LOX-1133): one git worktree per Linear issue, run **cursor-agent** in each worktree in parallel. Linear is the only source of state (no RALPH_TASK.md). Install into any repo via a one-liner; run from repo root with a project branch and a list of issue IDs.

## Prerequisites

- **cursor-agent** on your PATH. Install with:
  ```bash
  curl https://cursor.com/install -fsS | bash
  ```
  If missing, the runner exits with a clear error.

- **Linear MCP** configured in the consumer repo so that cursor-agent can call `get_issue`, `update_issue`, `create_comment` when executing each issue.

- **Commands and protocol** are installed by the script into `.cursor/commands/` and `.cursor/rules/` so the agent knows the workflow (execute-linear-task, protocol, orchestrate, review).

## Install (Option A: install script)

From your **project repo root** (the repo that has your code and Linear-backed work):

```bash
curl -fsSL https://raw.githubusercontent.com/symmatiq/ralph-wiggum-linear-cursor/main/install.sh | bash
```

This creates `.cursor/linear-ralph-scripts/`, `.cursor/rules/`, and `.cursor/commands/` with:

- `linear-parallel-run.sh` — main runner
- `prompts/linear-execute-single-issue.md` — prompt template for cursor-agent
- `.cursor/rules/linear-execution-protocol.mdc` — protocol (pre-flight, worktree mode, submit)
- `.cursor/commands/execute-linear-task.md` — run a single Linear issue (used by the agent in each worktree)
- `.cursor/commands/orchestrate-linear-work.md` — status, assign, Operation E (prepare parallel run)
- `.cursor/commands/review-pull-request.md` — review PRs (e.g. after a parallel run)
- `.cursor/commands/create-linear-project.md` — create Linear project and first issues

**Optional (recommended):** Install Cursor Agent Skills for more consistent pre-flight, worktree, and submit behavior when the agent runs in worktrees:

```bash
INSTALL_SKILLS=1 curl -fsSL https://raw.githubusercontent.com/symmatiq/ralph-wiggum-linear-cursor/main/install.sh | bash
```

This adds `.cursor/skills/` with `linear-pre-flight`, `linear-submit`, `linear-worktree-mode`, and `execute-linear-task`. The prompt template tells the agent to use these skills when present.

Idempotent: safe to run again to update scripts (and skills if `INSTALL_SKILLS=1`).

## Usage

From the **same repo root**:

```bash
./.cursor/linear-ralph-scripts/linear-parallel-run.sh
```

**Required (env or positional):**

- **PROJECT_BRANCH** — Git branch for the Linear project (e.g. `project/studio-ide`). PRs from each issue branch target this.
- **ISSUE_IDS** — Space-separated Linear issue IDs (e.g. `LOX-123 LOX-124 LOX-125`).

**Optional:**

- **MAX_PARALLEL** — Max concurrent cursor-agent jobs (default: `3`).
- **INTEGRATION_BRANCH** — If set, after all jobs finish the script merges each issue branch into this branch and pushes. You then open one PR from `INTEGRATION_BRANCH` → `PROJECT_BRANCH`.
- **--cleanup** — After a run, remove the worktrees (default: leave them for inspection).

**Worktrees:** By default each issue gets a worktree at `../.worktrees/<ISSUE_ID>` (relative to repo root). Override with **LINEAR_RALPH_WORKTREE_BASE** (absolute path).

**Examples:**

```bash
# Env only
PROJECT_BRANCH=project/studio-ide ISSUE_IDS="LOX-123 LOX-124" ./.cursor/linear-ralph-scripts/linear-parallel-run.sh

# With integration branch and cleanup
PROJECT_BRANCH=project/studio-ide ISSUE_IDS="LOX-123 LOX-124" INTEGRATION_BRANCH=integration/studio-ide ./.cursor/linear-ralph-scripts/linear-parallel-run.sh --cleanup

# Positional: branch then issue IDs
./.cursor/linear-ralph-scripts/linear-parallel-run.sh project/studio-ide LOX-123 LOX-124
```

**Output:** A table of issue ID, worktree path, branch, status (ok/fail), and log path. Logs live under `.cursor/linear-ralph-scripts/.logs/<ISSUE_ID>.log`.

**Review after run:** After the run, review each opened PR before merging. Use the review-linear-pr skill (or `.cursor/commands/review-pull-request.md`) with the PR number or branch; the agent validates requirements against the Linear issue and runs build/tests. See `.cursor/docs/parallel-linear-worktrees.md` for the full workflow.

## Waves (picking issues)

Run on a “wave” of issues that are ready and not blocking each other:

1. Use your Linear UI or an orchestrator (e.g. `orchestrate-linear-work` with “prepare parallel work”) to list ready issues (Todo, no unresolved blockers).
2. Pass the chosen issue IDs as **ISSUE_IDS**.
3. Optionally use **INTEGRATION_BRANCH** to merge all issue branches into one branch and open a single PR.

## Troubleshooting

| Problem | What to do |
|--------|------------|
| **cursor-agent not found** | Install: `curl https://cursor.com/install -fsS \| bash`. Ensure it’s on PATH in the shell that runs the script. |
| **Worktree already exists** | Script reuses it and ensures the branch is checked out. To start fresh: remove the worktree with `git worktree remove ../.worktrees/<ISSUE_ID>` (from repo root), then re-run. |
| **Merge conflicts on INTEGRATION_BRANCH** | Resolve in the repo: `git checkout <INTEGRATION_BRANCH>`, fix conflicts, commit, push. The script does not retry merges. |
| **Agent fails in worktree** | Inspect `.cursor/linear-ralph-scripts/.logs/<ISSUE_ID>.log`. Ensure Linear MCP and execute-linear-task/protocol are available in that repo. |

## License

MIT.

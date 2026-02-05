# Parallel Linear worktrees

Run multiple Linear issues in parallel: one git worktree per issue, **cursor-agent** in each worktree. Linear is the only source of state.

## Install

From this repo's root (the repo that has your code and Linear-backed work):

```bash
curl -fsSL https://raw.githubusercontent.com/Symmatiq/ralph-wiggum-linear-cursor/main/install.sh | bash
```

This creates **`.cursor/linear-ralph-scripts/`** with:

- `linear-parallel-run.sh` — main runner
- `prompts/linear-execute-single-issue.md` — prompt template for cursor-agent

**Optional:** Set `INSTALL_SKILLS=1` to also install Linear execution skills into `.cursor/skills/` (linear-pre-flight, linear-submit, linear-worktree-mode, execute-linear-task). Installing these skills improves consistency of agent behavior when running in worktrees; the prompt template directs the agent to use them when present.

Idempotent: safe to run again to update scripts (and skills if `INSTALL_SKILLS=1`).

## Usage

From the **same repo root**:

```bash
./.cursor/linear-ralph-scripts/linear-parallel-run.sh PROJECT_BRANCH=<branch> ISSUE_IDS="<id1> <id2> <id3>"
```

Example:

```bash
./.cursor/linear-ralph-scripts/linear-parallel-run.sh project/linear-first-parallel-runner "LOX-1134 LOX-1135 LOX-1136"
```

Required:

- **PROJECT_BRANCH** — Git branch for the Linear project (e.g. `project/linear-first-parallel-runner`). PRs from each issue branch target this branch.
- **ISSUE_IDS** — Space-separated Linear issue IDs.

Optional:

- **MAX_PARALLEL** — Max concurrent cursor-agent runs (default: 3). Example: `MAX_PARALLEL=2 ./...`
- **INTEGRATION_BRANCH** — After all runs, merge each issue branch into this branch and push. Example: `INTEGRATION_BRANCH=integration/parallel ./...`
- **--cleanup** — Remove worktrees (and optionally clean up) after the run.
- **LINEAR_RALPH_WORKTREE_BASE** — Base path for worktrees (default: `../.worktrees` relative to repo root).

## Waves

Run in batches: pick a first wave of ready issues (e.g. from Linear: Todo, no blockers), run the script. After review and merge, run a second wave. Use **orchestrate-linear-work** (Operation E) to get a ready-issue list and the exact runner command.

## Protocol and commands

- **Worktree mode**: When the agent runs inside a worktree created by the runner, it must **not** create another branch or worktree. See `.cursor/rules/linear-execution-protocol.mdc` and `.cursor/commands/execute-linear-task.md` (worktree mode).
- **Orchestrate**: Use `.cursor/commands/orchestrate-linear-work.md` → Operation E to prepare parallel work (project name, project branch, issue IDs or "next N ready") and get the run command.

## Review after run

After the parallel runner finishes, you can review each opened PR before merging. From the repo root (or in Cursor), for each PR opened by the run:

- Use the **review-linear-pr** skill (or run `.cursor/commands/review-pull-request.md`) with the PR number or branch. Example: "Review PR #12" or "Review the PR for LOX-123 using the review-linear-pr skill."
- The review agent will validate requirements against the Linear issue, check code quality, and run build/tests. Optionally post the review summary as a comment on the Linear issue.

## Troubleshooting

- **cursor-agent not found** — Install Cursor CLI so `cursor-agent` is on PATH (e.g. `curl https://cursor.com/install -fsS | bash`).
- **Worktree already exists** — Re-run is safe; existing worktrees are reused. Use `--cleanup` to remove them after a run.
- **Merge conflicts on INTEGRATION_BRANCH** — Resolve in repo; the script reports which branches failed to merge.
- **Linear MCP** — The consumer repo must have Linear MCP configured so cursor-agent can call `get_issue`, `update_issue`, `create_comment`, etc.

## External docs

- [ralph-wiggum-linear-cursor](https://github.com/Symmatiq/ralph-wiggum-linear-cursor) — README, install, and troubleshooting.

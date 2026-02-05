---
name: linear-worktree-mode
description: Detects and applies worktree mode for Linear issue execution. When the agent is run inside a parallel-runner-created worktree, skip branch/worktree creation and use the existing branch; still determine project branch for PR base. Use when executing a Linear issue and CWD may be a worktree created by linear-parallel-run.sh.
---

# Linear worktree mode

Use this when the agent is running **inside a worktree** that was already created by the parallel runner (`linear-parallel-run.sh`). In that case the branch and worktree exist; the agent must not create them again.

## When to use

- When executing a Linear issue and any of: env `LINEAR_RALPH_WORKTREE=1`; or current branch name matches `<ISSUE_ID>-linear` and CWD is not the main repo worktree root; or the prompt states "worktree mode" or "branch and worktree already created".

## Instructions

1. **Detection** – You are in worktree mode if: the prompt says the branch and worktree are already created, or `LINEAR_RALPH_WORKTREE=1` is set, or the current git branch is named like `<ISSUE_ID>-linear` and you are not in the main repo's working tree root.

2. **Skip** – Do not run any git commands to create a project branch, feature branch, or worktree. Do not run `git worktree add`. The parallel runner has already created the worktree and checked out the issue branch.

3. **Still do** – Run linear-pre-flight steps 1–4 (fetch issue, verify blockers, verify status, update Linear). Determine the **project branch** from the issue's Linear project name (e.g. `project/linear-first-parallel-runner`) so you know the PR base for submit.

4. **Submit** – When submitting, use linear-submit normally (push, PR to project branch, update Linear). Do not delete the worktree or branch; the runner may merge or cleanup later.

Reference: `.cursor/rules/linear-execution-protocol.mdc`, `.cursor/docs/parallel-linear-worktrees.md`.

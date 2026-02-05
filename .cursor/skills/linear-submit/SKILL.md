---
name: linear-submit
description: Completes a Linear issue after implementation: self-review, push branch, open PR to project branch, set issue to In Review, post completion comment. In worktree mode, do not delete branch or worktree. Use at the end of execute-linear-task when implementation and tests are done.
---

# Linear submit

Run this **after** implementation and tests pass. Pushes the branch, opens a PR against the project branch (never main or development), and updates Linear.

## When to use

- At the end of every execute-linear-task run when the issue is implemented and tests/build pass.
- When the user has finished implementing a Linear issue and wants to open a PR and update Linear.

## Instructions

1. **Self-review** – Confirm requirements are met, no lint/type errors, no TODO or placeholder without a Linear link, tests pass. Fix any issues before submitting.

2. **Push** – `git push -u origin <branch-name>`.

3. **Create PR** – `gh pr create --base <project-branch>` (the branch identified in pre-flight). Use title `[ISSUE-ID] [Issue Title]` and a body with Summary, Changes, Testing, Checklist, and "Fixes [LINEAR-ISSUE-URL]". Never use `--base main` or `--base development`.

4. **Verify base** – `gh pr view <PR-NUMBER> --json baseRefName`. If base is main or development, close the PR and recreate with the correct project branch.

5. **Update Linear** – Call `update_issue` to set state to In Review. Call `create_comment` with PR URL, branch name, summary of changes, files modified, and "Ready for Review".

6. **Worktree mode** – If this run is in worktree mode (parallel runner): Do **not** delete the worktree or branch. The runner may use INTEGRATION_BRANCH or `--cleanup` later. Leave branch and worktree for the runner to handle.

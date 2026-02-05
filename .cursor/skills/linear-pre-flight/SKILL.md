---
name: linear-pre-flight
description: Runs the pre-flight checklist for a Linear issue before implementation. Fetches issue, verifies blockers, updates Linear to In Progress, and either creates branch/worktree or skips in worktree mode. Use at the start of execute-linear-task or when the user is about to implement a Linear issue.
---

# Linear pre-flight

Run this **before** writing any code for a Linear issue. Ensures the issue is fetchable, unblocked, and that Linear state and git branch are ready.

## When to use

- At the start of every execute-linear-task run (standalone or worktree mode).
- When the user says they are starting work on a Linear issue and you need to validate and set up.

## Instructions

1. **Fetch issue** – Call Linear MCP `get_issue` with the issue ID. Extract title, status, priority, description, requirements, Blocked By, Test Plan.

2. **Verify blockers** – If the issue lists "Blocked By" (any blocker IDs), call `get_issue` for each. If any blocker is not Done, do not proceed; report and ask user to assign the blocker, wait, or override.

3. **Verify status** – If issue is Done, In Review, or Backlog (and user has not asked to run anyway), report and do not implement.

4. **Update Linear** – Call `update_issue` to set state to In Progress and assignee to "me". Call `create_comment` with a short body: branch name (or "worktree mode") and brief approach.

5. **Branch / worktree**:
   - **If in worktree mode** (see linear-worktree-mode skill or env `LINEAR_RALPH_WORKTREE=1` or branch name like `<ISSUE_ID>-linear`): Skip creating any branch or worktree. Only determine the **project branch** from the issue's Linear project (for PR base later). Proceed to implementation.
   - **Otherwise**: Determine project branch (e.g. `project/<project-name-kebab>`). If it does not exist, create it from `development`. Create feature branch from project branch (e.g. `<ISSUE_ID>-short-description`). Verify PR base will be the project branch.

After pre-flight, proceed to implementation (Phase 2), then use the linear-submit skill to push, open PR, and update Linear.

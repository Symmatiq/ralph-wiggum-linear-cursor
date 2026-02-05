---
name: orchestrate-linear-work
description: Manages the Linear work queue: status check, assign work, report progress, plan sprint, or prepare parallel run. Use when the user wants to check project status, assign a task to an agent or person, report completion or blockers, plan a sprint, or get a list of ready issues and the parallel runner command (Operation E).
---

# Orchestrate Linear work

Use this when the user wants to operate on a Linear project's work queue. Choose one operation and follow the full steps in `.cursor/commands/orchestrate-linear-work.md`.

## When to use

- User asks for project status, dashboard, or "how are we doing on project X".
- User wants work assigned (to "me", an agent, or a teammate).
- User wants to report progress (completed, blocked, failed) for an issue.
- User wants to plan a sprint (duration, capacity, prioritized list).
- User wants to prepare a parallel run: get ready issues and the exact `linear-parallel-run.sh` command (Operation E).

## Operations

| Operation | Input | Output |
|-----------|--------|--------|
| **A: Status check** | Project or team name | Dashboard: counts by status, ready queue, active work, blocked items, recommended next action |
| **B: Assign work** | Project, requester, capabilities, time available | One issue assigned (In Progress), comment added; execute-linear-task instructions |
| **C: Report progress** | Issue ID, status (completed/blocked/needs-review/failed), notes | Linear updated; impact analysis (newly unblocked, next recommended task) |
| **D: Plan sprint** | Project, duration, capacity | Sprint plan: committed work, execution order, parallel opportunities, risks |
| **E: Prepare parallel work** | Project name, project branch, optional issue IDs or N | Table of ready issues; install + run command for `linear-parallel-run.sh` |

## Instructions

1. Determine which operation the user needs (A–E). If unclear, ask.
2. Gather the required input (project name, project branch for E, etc.).
3. Follow the corresponding section in `.cursor/commands/orchestrate-linear-work.md` (query Linear, filter, generate output).
4. For Operation E: list ready issues (filter Blocked By), then output the exact runner command and optional INSTALL_SKILLS=1 and INTEGRATION_BRANCH/--cleanup usage.

Reference: `.cursor/commands/orchestrate-linear-work.md`, `.cursor/docs/parallel-linear-worktrees.md`.

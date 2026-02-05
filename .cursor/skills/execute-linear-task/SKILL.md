---
name: execute-linear-task
description: End-to-end execution of a single Linear issue: pre-flight, implement, test, submit. Composes linear-pre-flight, implementation and testing, then linear-submit. Use when the user wants to implement a Linear issue (standalone or in worktree mode).
---

# Execute Linear task

Run a single Linear issue from start to finish: pre-flight, implement, test, submit. Use the focused skills when present for consistent behavior.

## When to use

- When the user invokes execute-linear-task or asks to implement a Linear issue (e.g. "Execute LOX-123" or "Do this Linear issue").
- When the parallel runner has started the agent in a worktree with an issue ID and project branch in the prompt.

## Instructions

1. **Pre-flight** – Use the **linear-pre-flight** skill (or follow `.cursor/commands/execute-linear-task.md` Phase 1). If in worktree mode, use **linear-worktree-mode** so you skip branch/worktree creation.

2. **Implement** – Follow the issue requirements. Search the codebase for patterns, follow project rules, implement and commit incrementally. See Phase 2–3 of execute-linear-task.md for implementation and testing steps.

3. **Submit** – Use the **linear-submit** skill (or follow execute-linear-task.md Phase 4): self-review, push, open PR to project branch, set Linear to In Review, post completion comment. In worktree mode do not delete branch/worktree.

## References

- `.cursor/commands/execute-linear-task.md` – Full step-by-step command.
- `.cursor/rules/linear-execution-protocol.mdc` – Protocol summary and worktree mode.
- Skills: linear-pre-flight, linear-submit, linear-worktree-mode.

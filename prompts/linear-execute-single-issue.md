You are executing a single Linear issue in **worktree mode**. The branch and worktree are already created; do not create them again.

- **Linear issue ID**: `{{ISSUE_ID}}`
- **Project branch** (PR target): `{{PROJECT_BRANCH}}`
- **Current working directory**: the worktree root for this issue.

## Instructions

1. **Follow this repo's workflow**
   - Read and follow: `.cursor/commands/execute-linear-task.md`
   - Follow the rules in: `.cursor/rules/linear-execution-protocol.mdc` (if present)

2. **Do not create branch or worktree**
   - Branch and worktree already exist. Work in the current directory.

3. **Use Linear as the only state**
   - Use Linear MCP for all state: `get_issue`, `update_issue`, `create_comment`.
   - Do not create or rely on RALPH_TASK.md or other local task files.

4. **When done**
   - Run tests and fix any failures.
   - Push the branch, open a PR against `{{PROJECT_BRANCH}}`, and set the issue to **In Review** with a completion comment (as per execute-linear-task).

5. **If you cannot complete**
   - If blocked or requirements are ambiguous: set the issue to **Blocked** (or add a clear comment), then exit non-zero so the runner can report failure.

Implement the issue fully, then complete the Submit phase (push, PR, Linear update) before exiting.

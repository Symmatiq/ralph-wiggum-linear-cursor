# Execute Linear Task

You are an AI coding agent executing a specific Linear issue. Implement the task completely, following all requirements, conventions, and quality standards.

**⚠️ MANDATORY: Follow [linear-execution-protocol.mdc](.cursor/rules/linear-execution-protocol.mdc).**
Complete Pre-flight (fetch issue, verify blockers, update Linear to In Progress + comment, create branch **or** use existing branch in worktree mode) **before** writing any code. Complete Submit (commit, push, PR against project branch, update Linear to In Review + comment) **after** implementation.

### Worktree mode

If you are running **inside a worktree created by the parallel runner** (e.g. `linear-parallel-run.sh`), **skip** Step 1.5 branch/worktree creation. The branch and worktree already exist; CWD is the worktree root. Still do Steps 1.1–1.4 and determine the project branch for the PR base. See [linear-execution-protocol.mdc](.cursor/rules/linear-execution-protocol.mdc) and [parallel-linear-worktrees.md](.cursor/docs/parallel-linear-worktrees.md). Detection: env `LINEAR_RALPH_WORKTREE=1` or current branch name matches `<ISSUE_ID>-linear` and CWD is not the main repo worktree root.

---

## ⛔ CRITICAL: BRANCH WORKFLOW RULES

**NEVER create PRs directly to `main`. This is FORBIDDEN.**

The workflow is:
1. A **project branch** is created from `development` (e.g., `project/<project-name>`)
2. Issue/feature branches are created from the **project branch**
3. PRs for issues are opened against the **project branch**
4. When the project is complete, merge **project branch → development**
5. Only `development` is merged to `main` (release process)

**If you violate this rule, you will corrupt the release process.**

---

## INPUT REQUIRED

You MUST have:
- **Issue ID**: The Linear issue identifier (e.g., "PROJ-123", "ENG-456")

You MUST determine (in Step 1.5):
- **Project Branch**: The branch this issue's PR will target (e.g., `project/blueprint-s3-sync`)
  - If not provided, derive from the Linear project name
  - If no project branch exists, CREATE ONE from `development`
  - **NEVER default to `development` or `main`** - always use a `project/` branch

If issue ID is not provided, ASK the user. Do not proceed without it.
If project branch cannot be determined, ASK the user. Do not proceed without it.

---

## PHASE 1: PRE-FLIGHT CHECK

### Step 1.1: Fetch Issue Details

```
TOOL: user-linear-get_issue
PARAMETERS:
  id: "[ISSUE-ID]"
```

Read the full response. Extract and document:

```markdown
## Issue: [ISSUE-ID]

**Title**: [Title from Linear]
**Status**: [Current status]
**Priority**: [P level]
**Assignee**: [Name or Unassigned]

### Objective
[From issue description]

### Requirements
- [ ] [Requirement 1]
- [ ] [Requirement 2]

### Files to Modify
- [File 1]
- [File 2]

### Blocked By
[List of blocking issues, or "None"]

### Test Plan
[From issue description]
```

### Step 1.2: Verify Ready to Start

**Check blockers**: If "Blocked By" contains issue IDs, query each:

```
TOOL: user-linear-get_issue
PARAMETERS:
  id: "[BLOCKER-ID]"
```

| Blocker | Required: Done | Actual Status | OK? |
|---------|----------------|---------------|-----|
| [ID] | Done | [Status] | ✅/❌ |

**If ANY blocker is NOT Done**:
1. Do NOT proceed
2. Report: "Cannot start [ISSUE-ID]: blocked by [BLOCKER-ID] which is [status]"
3. Ask user to either:
   - Assign you the blocker instead
   - Wait for blocker completion
   - Override (user takes responsibility)

### Step 1.3: Verify Status

If issue status is not `Todo` or `In Progress`:
- If `Done`: "This issue is already completed"
- If `In Review`: "This issue is awaiting review, not implementation"
- If `Backlog`: "This issue is not ready for work yet"

### Step 1.4: Update Linear

```
TOOL: user-linear-update_issue
PARAMETERS:
  id: "[ISSUE-ID]"
  state: "In Progress"
  assignee: "me"
```

```
TOOL: user-linear-create_comment
PARAMETERS:
  issueId: "[ISSUE-ID]"
  body: "Starting implementation.\n\n**Branch**: `[ISSUE-ID]-[short-description]`\n**Approach**: [Brief summary of plan]"
```

### Step 1.5: Identify or Create Project Branch

**⛔ MANDATORY: You MUST have a project branch. NEVER skip this step.**

**If in worktree mode** (see above): Skip Steps 1.5a–1.5d. The feature branch and worktree already exist. Only **identify** the project branch (from Linear project name) for use as PR base in Phase 4. Then proceed to Phase 2.

**Step 1.5a: Check if project branch exists**

```bash
git fetch origin
git branch -a | grep -i "project/"
```

Look for a branch matching the Linear project name (e.g., `project/blueprint-s3-sync` for project "Blueprint S3 Sync").

**Step 1.5b: If NO project branch exists, CREATE ONE**

```bash
# Create project branch from development
git checkout development
git pull origin development
git checkout -b project/[project-name-kebab-case]
git push -u origin project/[project-name-kebab-case]
```

Example: For project "Blueprint S3 Sync" → `project/blueprint-s3-sync`

**Step 1.5c: If project branch is UNCLEAR**

**STOP and ASK the user**: "What is the project branch for this issue? The Linear project is '[PROJECT-NAME]'. Should I create `project/[suggested-name]`?"

**DO NOT proceed without explicit confirmation of the project branch.**

**Step 1.5d: Create feature branch FROM project branch**

```bash
git checkout [project-branch]
git pull origin [project-branch]
git checkout -b [ISSUE-ID]-[short-description]

# Example: git checkout -b LOX-1070-add-sync-runs-migration
```

**⚠️ VERIFY before proceeding**:
- [ ] Project branch exists (either found or created)
- [ ] Feature branch was created FROM project branch (not from `development` or `main`)
- [ ] You know what `--base` to use for the PR (the project branch name)

---

## PHASE 2: IMPLEMENTATION

### Step 2.1: Understand Before Coding

Before writing ANY code:

1. **Find similar code** in the codebase
   ```
   TOOL: SemanticSearch
   PARAMETERS:
     query: "How is [similar feature] implemented?"
     target_directories: []
   ```

2. **Identify patterns** to follow from this repo's rules (e.g. in `.cursor/rules/`): API structure, workers/bots, event patterns, database conventions—use whatever the project defines.

3. **Check for existing utilities** in `lib/`, `shared/`, or equivalent

Document your understanding:
```markdown
### Implementation Plan
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Patterns to Follow
- [Pattern from existing code]
- [Pattern from rules]

### Reusable Code Found
- [Utility/helper to use]
```

### Step 2.2: Implement

For each file listed in requirements:

**Before modifying**: Read the file first, understand context
**While modifying**: Follow project conventions
**After modifying**: Verify no lint/type errors

### Code Quality Checklist (MUST PASS)

- [ ] TypeScript strict mode compatible
- [ ] No `any` types (or justified with comment)
- [ ] Error handling for all async operations
- [ ] No hardcoded secrets or PII
- [ ] Uses project logger, not console.log
- [ ] Functions < 50 lines
- [ ] Files < 300 lines

### Step 2.3: Commit Incrementally

```bash
# Format: [ISSUE-ID]: [what changed]
git add [files]
git commit -m "[ISSUE-ID]: [brief description]"
```

Good commit examples:
- `PROJ-123: Add user roles schema and types`
- `PROJ-123: Implement roles API endpoint`
- `PROJ-123: Add input validation with Zod`
- `PROJ-123: Add unit tests for roles API`

### Step 2.4: Handle Problems

**If you discover additional work needed**:
```markdown
## ⚠️ Scope Discovery

**Original**: [What issue asked for]
**Discovered**: [Additional work found]

**Options**:
1. Include in this PR (adds ~[X] hours)
2. Create follow-up issue (document and proceed with original scope)
3. Stop and discuss (this changes the task significantly)

**My Recommendation**: [Option X] because [reason]
```

**If you hit a technical blocker**:
```markdown
## 🔴 Technical Blocker

**Problem**: [Description]
**Tried**:
1. [Attempt 1]
2. [Attempt 2]

**Need**: [What would unblock this]

**Can I proceed?**: [Yes with workaround / No, help]
```


**If you discover TODOs, placeholders, stubs, or missing dependencies**:

**MANDATORY**: Create a Linear task for any of the following:

1. **Missing Providers/Contexts**: When a component uses a context hook but the provider is missing
   - Example: `useBillingContext must be used within a BillingProvider`
   - Example: `useAuthContext must be used within an AuthProvider`

2. **TODO Comments**: Any TODO that represents incomplete work (not just "optimize later")
   - Example: `// TODO: Get from API when available`
   - Example: `// TODO: Add error handling`
   - Example: `// TODO: Implement validation`

3. **Placeholder/Mock Data**: When code uses mock data that should be replaced
   - Example: `const mockData = [...] // TODO: Replace with API`
   - Example: `// Using placeholder until API is ready`

4. **Stub Functions**: Empty or throw-not-implemented functions
   - Example: `function processData() { throw new Error("Not implemented"); }`
   - Example: `async function fetchData() { return []; } // Stub`

5. **Build/Runtime Errors**: Errors discovered during build or testing that are unrelated to current work
   - Example: Build fails on unrelated page during static generation
   - Example: Missing dependency that blocks other features

**Process for Creating Follow-up Tasks**:

Use `mcp_linear_create_issue` with:
- `team`: Team name or ID (from the current issue's project or user input)
- `title`: Concise description
- `description`: Include Problem, Context, Requirements, Technical Approach, Test Plan, Priority
- `priority`: 1-4 based on impact (1=Urgent, 2=High, 3=Normal, 4=Low)
- `labels`: ["domain", "bug" | "chore" | "technical-debt"]

**After creating the task**:

1. Add a comment to current Linear issue linking the new task using `mcp_linear_create_comment`
2. Document in completion report under "Follow-up Items"

**Examples**:

✅ **DO create tasks for**: Missing providers, incomplete TODOs, mock data to replace, stubs, pre-existing bugs
❌ **DON'T create tasks for**: Minor optimizations, style improvements, non-critical docs, refactoring suggestions


---

## PHASE 3: TESTING

### Step 3.1: Write Tests

From the issue's Test Plan, implement tests:

```typescript
// Location: alongside the code or in test/ directory
describe('[Feature from issue]', () => {
  it('should [requirement 1 from issue]', async () => {
    // Arrange
    // Act
    // Assert
  });

  it('should [requirement 2 from issue]', async () => {
    // ...
  });

  it('should handle [error case]', async () => {
    // ...
  });
});
```

### Step 3.2: Run Tests

```bash
# Run tests
pnpm test

# Run with coverage (if supported)
pnpm test --coverage
```

### Step 3.3: Verify Build

```bash
# Type check
pnpm typecheck

# Lint
pnpm lint

# Build
pnpm build
```

**If any fail**: Fix before proceeding. Do NOT create PR with failing tests/build.

### Step 3.4: Document Results

```markdown
### Test Results

**Tests**: [X] passed, [X] failed
**Coverage**: [X]% (target: ≥80%)
**Build**: ✅ Pass / ❌ Fail
**Lint**: ✅ Pass / ❌ Fail
**TypeCheck**: ✅ Pass / ❌ Fail
```

---

## PHASE 4: SUBMIT

### Step 4.1: Self-Review Checklist

Before creating PR, verify:

**Requirements**:
- [ ] All requirements from issue implemented
- [ ] Acceptance criteria met
- [ ] No scope creep (only what was asked)

**Code**:
- [ ] No lint errors
- [ ] No TypeScript errors
- [ ] No console.log (use logger)
- [ ] No commented-out code
- [ ] No TODO without issue link (create Linear task if found)
- [ ] No placeholder/mock data without issue link (create Linear task if found)
- [ ] No missing providers/contexts (create Linear task if found)

**New API endpoints / services** (if creating new endpoints or workers):
- [ ] Follow this project's conventions for package structure, config, and deployment (see `.cursor/rules/` or project docs)
- [ ] Required metadata present (version, entry point, handler/config as defined by the project)

**Tests**:
- [ ] All tests pass
- [ ] Coverage ≥80% on new code
- [ ] Edge cases covered

**Security**:
- [ ] No secrets in code
- [ ] No PII logged
- [ ] Input validation present

### Step 4.2: Push and Create PR

**⛔ CRITICAL: PRs MUST target the project branch. NEVER target `development` or `main` directly.**

```bash
# Push branch
git push -u origin [branch-name]
```

**Before running `gh pr create`, verify you have the correct project branch:**
```bash
# The project branch you identified in Step 1.5
echo "PR will target: [project-branch]"
```

```bash
# ⛔ CRITICAL: --base MUST be the project branch (e.g., project/blueprint-s3-sync)
# NEVER use --base development or --base main!
gh pr create --base [project-branch] --title "[ISSUE-ID] [Issue Title]" --body "$(cat <<'EOF'
## Summary
[2-3 sentences on what this PR does]

## Changes
- [Change 1]
- [Change 2]
- [Change 3]

## Testing
- [X] Unit tests added/updated
- [X] Manual testing performed
- [X] Build passes

## Checklist
- [X] Requirements complete
- [X] Tests pass
- [X] No lint/type errors

Fixes [LINEAR-ISSUE-URL]
EOF
)"
```

**⚠️ MANDATORY VERIFICATION** (do not skip):

```bash
# Immediately after creating PR, verify the base branch
gh pr view [PR-NUMBER] --json baseRefName
```

Expected output: `{"baseRefName":"project/[project-name]"}`

**If baseRefName is `development` or `main`**:
1. Close the PR: `gh pr close [PR-NUMBER] --comment "Closing: wrong base branch"`
2. Recreate with correct `--base project/[project-name]`

### Step 4.3: Update Linear

```
TOOL: user-linear-update_issue
PARAMETERS:
  id: "[ISSUE-ID]"
  state: "In Review"
```

```
TOOL: user-linear-create_comment
PARAMETERS:
  issueId: "[ISSUE-ID]"
  body: "## Implementation Complete\n\n**PR**: [PR-URL]\n**Branch**: `[branch-name]`\n\n### Changes\n- [Summary of what was built]\n\n### Files Modified\n- `path/file1.ts` - [what changed]\n- `path/file2.ts` - [what changed]\n\n### Test Coverage\n[X]% coverage on new code\n\n### Ready for Review\nPR is ready for code review."
```

### Step 4.4: Worktree mode – cleanup

**If you are in worktree mode** (parallel runner): Do **not** delete the worktree or the branch. The runner may merge all issue branches into an integration branch (`INTEGRATION_BRANCH`) and/or run with `--cleanup` to remove worktrees after all issues complete. Leave branch and worktree for the runner to handle.

---

## PHASE 5: HANDOFF

### Step 5.1: Completion Report

```markdown
## ✅ Task Complete: [ISSUE-ID]

**Issue**: [ISSUE-ID] - [Title]
**PR**: [PR-URL]
**Branch**: [branch-name]
**Status**: In Review

### What Was Built
[2-3 sentences]

### Files Changed
| File | Action | Lines |
|------|--------|-------|
| [path] | [create/modify] | +[X], -[X] |

### Tests
- [X] passed, [X]% coverage

### Time
- Estimated: [X]h
- Actual: [X]h

### Unblocked by This Work
[List issues that can now proceed, or "None"]

### Follow-up Items
- [ ] [Any discovered work for new issues]

### Next Step
PR ready for review. Use `@.cursor/commands/review-pull-request.md` with PR number [X].
```

---

## ERROR RECOVERY

### Build Fails
1. Read error message carefully
2. **Check if error is related to current work**:
   - If YES: Fix the issue, commit, and continue
   - If NO: Create Linear task for the unrelated issue (see "If you discover TODOs..." section), document in current issue, and proceed with current work
3. If fixing: Commit fix: `[ISSUE-ID]: Fix build error - [description]`
4. Push and verify CI passes

### Tests Fail
1. Determine if test is correct or code is wrong
2. Fix the appropriate one
3. Re-run full test suite
4. Commit fix

### Merge Conflicts
```bash
git fetch origin
git checkout [base-branch]
git pull
git checkout [your-branch]
git rebase [base-branch]
# Resolve conflicts
git add .
git rebase --continue
git push --force-with-lease
```

### PR Review Feedback
1. Read all feedback
2. Make changes in new commits (don't rewrite history after review starts)
3. Reply to each comment
4. Request re-review

---

## STATUS TRANSITIONS

```
Todo → In Progress      (when starting work)
In Progress → In Review (when PR created)
In Review → Done        (when PR merged) ← REVIEWER/ORCHESTRATOR does this
In Progress → Todo      (if blocked, need clarification)
```

**Note**: Moving to `Done` happens after merge, typically by the reviewer or orchestrator, not the implementer.

---

## REFERENCE

- **Create Project**: `@.cursor/commands/create-linear-project.md`
- **Orchestrator**: `@.cursor/commands/orchestrate-linear-work.md`
- **Review PR**: `@.cursor/commands/review-pull-request.md`
- **Linear Conventions**: `@.cursor/rules/linear-task-management.mdc` (if present)
- **Code / API / DB patterns**: See `.cursor/rules/` in the project for API, workers, and database conventions

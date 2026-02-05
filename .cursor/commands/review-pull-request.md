# Review Pull Request

You are a senior staff engineer conducting a thorough code review. Validate that a PR accomplishes its task, follows standards, and meets quality gates.

---

## INPUT REQUIRED

You MUST have ONE of:
- **PR Number**: The pull request number (e.g., "123", "#123")
- **PR URL**: Full GitHub PR URL
- **Branch Name**: If currently on the PR branch

Optional:
- **Review Focus**: `full` (default), `quick`, `security`, `performance`
- **Linear Issue ID**: If not in PR body, provide explicitly

If not provided, ASK the user.

---

## REVIEW MODES

| Mode | What It Does | When to Use |
|------|-------------|-------------|
| `full` | All 9 phases | Before merging to main branches |
| `quick` | Phases 1, 4 only | CI passed, just need sanity check |
| `security` | Phases 1, 2, 5 | Security-sensitive changes |
| `performance` | Phases 1, 2, 6 | Performance-critical code |

Default is `full` if not specified.

---

## PHASE 1: CONTEXT GATHERING

### Step 1.1: Get PR Details

```bash
gh pr view [PR-NUMBER] --json number,title,body,state,additions,deletions,changedFiles,baseRefName,headRefName,author
```

### Step 1.2: Get Changed Files

```bash
gh pr diff [PR-NUMBER] --name-only
```

### Step 1.3: Extract Linear Issue

Look in PR body for:
- `Fixes https://linear.app/...`
- `Closes https://linear.app/...`
- `[PROJ-123]` in title

If found:
```
TOOL: user-linear-get_issue
PARAMETERS:
  id: "[ISSUE-ID]"
```

If NOT found: Ask user for issue ID, or note "No linked issue found"

### Step 1.4: Document Context

```markdown
## 📋 Review Context

**PR**: #[NUMBER] - [Title]
**Author**: [Author]
**Branch**: [head] → [base]
**State**: [Open/Draft]

**Changes**: [X] files, +[X] lines, -[X] lines

**Linear Issue**: [ISSUE-ID] - [Title] (or "None linked")

### Changed Files
| File | Type |
|------|------|
| [path/file1.ts] | modified |
| [path/file2.ts] | added |
| [path/file3.ts] | deleted |
```

---

## PHASE 2: REQUIREMENTS VALIDATION

### Step 2.1: Extract Requirements

From Linear issue (if available):

```markdown
## Requirements Check

### From Issue [ISSUE-ID]

**Objective**: [What was asked]

**Requirements**:
1. [ ] [Requirement 1]
2. [ ] [Requirement 2]
3. [ ] [Requirement 3]

**Acceptance Criteria**:
- [ ] [Criteria 1]
- [ ] [Criteria 2]
```

### Step 2.2: Verify Implementation

Read each changed file. For each requirement:

```markdown
### Requirement → Implementation Mapping

| # | Requirement | Implemented? | Where |
|---|-------------|--------------|-------|
| 1 | [desc] | ✅ Yes | `file.ts:45-60` |
| 2 | [desc] | ⚠️ Partial | `file.ts:70` - missing X |
| 3 | [desc] | ❌ No | Not found |
```

### Step 2.3: Scope Check

```markdown
### Scope Analysis

**Expected Changes** (from requirements):
- ✅ [Feature A] - implemented
- ✅ [Feature B] - implemented
- ❌ [Feature C] - missing

**Unexpected Changes** (not in requirements):
- ⚠️ [Refactoring X] - not requested, acceptable/concerning?
- ⚠️ [Feature Y] - scope creep?

**Verdict**: ✅ On scope / ⚠️ Scope creep / ❌ Incomplete
```

---

## PHASE 3: CODE QUALITY

### Step 3.1: Pattern Compliance

Read the changed files. Check against project rules (if present in this repo):

```markdown
## Pattern Compliance

### API Endpoints
Use project rules in `.cursor/rules/` for API structure (if present).
- [ ] Uses project patterns for API structure
- [ ] Directory structure consistent
- [ ] Validation for inputs
- [ ] Standard error handling

### Bots / Workers
Use project rules for workers/bots (if present).
- [ ] Uses project handler patterns
- [ ] Schema for events
- [ ] Errors handled

### Database
Use project rules for database conventions (if present).
- [ ] Correct naming and migrations

### General
- [ ] No `any` types (or justified)
- [ ] Proper function types
- [ ] Single responsibility, DRY
```

### Step 3.2: Code Style

```markdown
### Code Style

**TypeScript**:
- [ ] No `any` types (or justified)
- [ ] Proper function types
- [ ] Strict mode compatible

**Naming**:
- [ ] Functions: camelCase, verb-first
- [ ] Types: PascalCase
- [ ] Constants: UPPER_SNAKE_CASE

**Organization**:
- [ ] Functions < 50 lines
- [ ] Files < 300 lines
- [ ] No commented-out code
```

### Step 3.3: File-by-File Review

For each changed file, note issues:

```markdown
### File: `[path/to/file.ts]`

**Purpose**: [What this file does]

**Issues Found**:
| Line | Severity | Issue | Fix |
|------|----------|-------|-----|
| 45 | 🔴 High | [Issue] | [Fix] |
| 78 | 🟡 Medium | [Issue] | [Fix] |

**Good Practices Observed**:
- [Positive observation]
```

---

## PHASE 4: BUILD & TESTS

### Step 4.1: Run Checks

```bash
# Lint (if available)
pnpm lint  # or npm run lint

# Type check (if available)
pnpm typecheck

# Tests (if available)
pnpm test

# Build (if available)
pnpm build
```

Skip checks that don't exist in the project.

### Step 4.2: Document Results

```markdown
## Build & Test Results

| Check | Status | Details |
|-------|--------|---------|
| Lint | ✅/❌/N/A | [X errors or "not present"] |
| TypeCheck | ✅/❌/N/A | [X errors] |
| Tests | ✅/❌/N/A | [X passed, X failed] |
| Build | ✅/❌/N/A | [Build time] |

**Coverage** (if available): [X]% on new code. Target ≥80%.
```

If any check fails: This is a **blocking issue** - must be fixed before approval.

---

## PHASE 5: SECURITY

### Step 5.1: Security Checklist

```markdown
## 🔒 Security Review

### Input Validation
- [ ] All inputs validated
- [ ] No raw SQL (parameterized only)
- [ ] File uploads validated if applicable

### Authentication & Authorization
- [ ] Auth required where appropriate
- [ ] No hardcoded credentials

### Data Protection
- [ ] No PII in logs
- [ ] Error messages sanitized
```

### Step 5.2: Security Findings

```markdown
### Security Issues

| ID | Severity | Issue | Location | Recommendation |
|----|----------|-------|----------|----------------|
| S1 | 🔴 Critical | [Issue] | [File:Line] | [Fix] |

**Security Verdict**: ✅ Pass / ⚠️ Pass with notes / ❌ Fail
```

Critical or High security issues are **blocking**.

---

## PHASE 6: PERFORMANCE

### Step 6.1: Performance Checklist

```markdown
## ⚡ Performance Review

### Database
- [ ] Queries indexed where needed
- [ ] No N+1 patterns
- [ ] Pagination for lists

### API / Lambda
- [ ] Response payload minimal
- [ ] Timeouts configured
```

### Step 6.2: Performance Findings

```markdown
### Performance Findings

| ID | Severity | Issue | Location | Fix |
|----|----------|-------|----------|-----|
| P1 | 🔴 High | [Issue] | [File:Line] | [Fix] |

**Performance Verdict**: ✅ Good / ⚠️ Concerns / ❌ Blocking issues
```

---

## PHASE 7: SCALABILITY

```markdown
## 📈 Scalability Review

### Checklist
- [ ] Stateless design where appropriate
- [ ] Handles larger data gracefully
- [ ] Idempotent where needed

### Concerns
| Issue | Risk at Scale | Severity |
|-------|---------------|----------|
| [Issue] | [Risk] | 🟡 Medium |

**Scalability Verdict**: ✅ Good / ⚠️ Concerns / ❌ Not scalable
```

---

## PHASE 8: MAINTAINABILITY

```markdown
## 🔧 Maintainability Review

### Checklist
- [ ] Self-documenting code
- [ ] Follows existing patterns
- [ ] Tests are clear
- [ ] No new technical debt

**Maintainability Verdict**: ✅ Excellent / ⚠️ Good / 🟡 Needs work / ❌ Poor
```

---

## PHASE 9: FINAL VERDICT

### Step 9.1: Calculate Score

```markdown
## 📊 Review Summary

**PR**: #[NUMBER] - [Title]
**Reviewer**: AI Review Agent
**Date**: [Date]

### Scores
| Category | Score | Notes |
|----------|-------|-------|
| Requirements | [X]/10 | [Status] |
| Code Quality | [X]/10 | [Status] |
| Tests | [X]/10 | [Status] |
| Build | [X]/10 | [Status] |
| Security | [X]/10 | [Status] |
| Performance | [X]/10 | [Status] |
| Scalability | [X]/10 | [Status] |
| Maintainability | [X]/10 | [Status] |
| **Total** | **[X]/80** | |

### Issue Count
| Severity | Count |
|----------|-------|
| 🔴 Critical | [X] |
| 🔴 High | [X] |
| 🟡 Medium | [X] |
| 🟢 Low | [X] |
```

### Step 9.2: Determine Verdict

**Decision Logic**:
- **APPROVE**: Score ≥ 60/80 AND 0 Critical AND 0 High AND Build/Tests pass
- **REQUEST CHANGES**: Score < 60 OR any Critical/High OR Build/Tests fail
- **REJECT**: Fundamental issues requiring complete rewrite

### Step 9.3: Output Verdict

```markdown
## 🎯 VERDICT: [APPROVE / REQUEST CHANGES / REJECT]

### Summary
[2-3 sentences explaining decision]

### Required Changes (if REQUEST CHANGES)
- [ ] [Change 1 - with file:line]
- [ ] [Change 2 - with file:line]

### Recommended Improvements (optional)
- [ ] [Suggestion 1]
```

### Step 9.4: Post Review

```bash
# If APPROVE
gh pr review [PR-NUMBER] --approve --body "## ✅ Approved

[Summary]

### Verified
- ✅ Requirements complete
- ✅ Tests pass
- ✅ Build succeeds
- ✅ Security: No issues

Score: [X]/80. Ready to merge."
```

```bash
# If REQUEST CHANGES
gh pr review [PR-NUMBER] --request-changes --body "## ⚠️ Changes Requested

[Summary]

### Must Fix
- [ ] [Issue 1] - [File:Line]
- [ ] [Issue 2] - [File:Line]

Score: [X]/80. Please address and request re-review."
```

### Step 9.5: Update Linear

```
TOOL: user-linear-create_comment
PARAMETERS:
  issueId: "[ISSUE-ID]"
  body: "## Code Review: [APPROVE/REQUEST CHANGES]\n\n**PR**: #[NUMBER]\n**Score**: [X]/80\n\n### Summary\n[Summary]\n\n### Required Changes\n- [If any]\n\n### Next Steps\n[What happens next]"
```

---

## POST-MERGE: CLOSE THE LOOP

After PR is merged:

```
TOOL: user-linear-update_issue
PARAMETERS:
  id: "[ISSUE-ID]"
  state: "Done"
```

```
TOOL: user-linear-create_comment
PARAMETERS:
  issueId: "[ISSUE-ID]"
  body: "## ✅ Completed\n\nPR #[NUMBER] merged to [base-branch].\n\nThis issue is now Done."
```

### Clean Up Local Repository

```bash
PR_BRANCH=$(gh pr view [PR-NUMBER] --json headRefName -q .headRefName)
git checkout -- .
git clean -fd
git checkout development
git pull origin development
git branch -D "$PR_BRANCH"
```

**Verify**: `git status` shows clean, `git branch` shows `development`.

---

## QUICK MODE (Phases 1 & 4 only)

For quick sanity checks when CI has passed:

```markdown
## Quick Review: PR #[NUMBER]

**Changed Files**: [X]
**CI Status**: ✅ Passed

### Sanity Checks
- [ ] Changes look reasonable for issue scope
- [ ] No obvious code smells
- [ ] No secrets/credentials
- [ ] Tests exist for new code

**Quick Verdict**: ✅ LGTM / ⚠️ Needs full review
```

---

## REFERENCE

- **Create Project**: `@.cursor/commands/create-linear-project.md`
- **Orchestrator**: `@.cursor/commands/orchestrate-linear-work.md`
- **Execute Task**: `@.cursor/commands/execute-linear-task.md`

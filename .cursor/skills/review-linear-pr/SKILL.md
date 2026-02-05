---
name: review-linear-pr
description: Conducts a thorough code review of a pull request, optionally linked to a Linear issue. Validates requirements, code quality, build and tests, security and performance as needed. Use when reviewing a PR tied to a Linear issue or when the user asks for a PR review.
---

# Review Linear PR

Use this when the user wants to review a pull request, especially one that fixes or implements a Linear issue. Follow the full phases in `.cursor/commands/review-pull-request.md`.

## When to use

- User asks to review a PR (by number, URL, or branch).
- User asks to review "the PR for LOX-123" or "PRs from the last parallel run".
- After a parallel run, to review each opened PR before merge.

## Instructions

1. **Get PR and context** – Use `gh pr view` and `gh pr diff` to get PR details and changed files. Extract Linear issue from PR body/title (Fixes/Closes link or issue ID). If linked, fetch issue via Linear MCP for requirements.

2. **Run review phases** – Follow `.cursor/commands/review-pull-request.md`:
   - Phase 1: Context (PR details, changed files, Linear issue).
   - Phase 2: Requirements validation (issue requirements vs implementation).
   - Phase 3: Code quality (patterns, style, file-by-file).
   - Phase 4: Build and tests (lint, typecheck, test, build).
   - Phases 5–9 as needed (security, performance, etc.; or use mode: quick/security/performance).

3. **Output** – Produce a structured review: context, requirements check, scope, code quality, test results, summary, and approve/request changes. If the repo uses Linear, add a comment to the Linear issue with the review summary when appropriate.

Reference: `.cursor/commands/review-pull-request.md`.

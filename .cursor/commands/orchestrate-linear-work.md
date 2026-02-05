# Orchestrate Linear Work Queue

You are an AI orchestration agent managing a multi-agent development workflow. Maintain the work queue, assign tasks, monitor progress, handle blockers, and ensure efficient parallel execution.

---

## INPUT REQUIRED

You need ONE of the following to proceed:

### Global Context (recommended)
- **Project Branch**: The git branch representing this Linear project (created from `development`), e.g. `project/pko-context-graphs-mvp`

### Option A: Status Check
- **Project or Team**: Name of Linear project or team to check

### Option B: Assign Work  
- **Project or Team**: Where to find work
- **Requester**: Who needs work (e.g., "backend agent", "me", or agent identifier)
- **Capabilities**: What domains they can handle (backend, frontend, etc.)
- **Time Available**: How many hours available (optional, defaults to 4h)

### Option C: Report Progress
- **Issue ID**: Which task to update (e.g., "PROJ-123")
- **Status**: One of: `completed`, `blocked`, `needs-review`, `failed`
- **Notes**: What happened (required for blocked/failed)

### Option D: Plan Sprint
- **Project or Team**: What to plan
- **Duration**: How many days (e.g., 5 days, 10 days)
- **Capacity**: Available agent-hours

### Option E: Prepare parallel work (Linear-first)
- **Project name**: Linear project (e.g. "Linear-First Parallel Runner (Option B)")
- **Project branch**: Git branch for the project (e.g. `project/linear-first-parallel-runner`)
- **Issue IDs** (optional): Specific issue IDs, or omit to get "next N ready"
- **N** (optional): If no issue IDs given, take first N ready issues (default: all ready)

Ask the user which operation they need if not clear from context.

---

## OPERATION A: STATUS CHECK

### Step 1: Query Linear

```
TOOL: user-linear-list_issues
PARAMETERS:
  project: "[Project Name]"
  limit: 100
```

### Step 2: Categorize Issues

Group issues by their current state:

| Status | Linear State | Meaning |
|--------|-------------|---------|
| 🟢 Ready | `Todo` + no blockers in description | Can start now |
| 🔵 In Progress | `In Progress` | Currently being worked |
| 🟡 In Review | `In Review` | Awaiting PR review/merge |
| 🔴 Blocked | `Todo` + has blockers OR `Blocked` | Cannot proceed |
| ✅ Done | `Done` or `Completed` | Finished |
| ⚪ Backlog | `Backlog` or `Triage` | Not ready for work |

### Step 3: Generate Dashboard

```markdown
## 📊 Project Status: [Project Name]
**Generated**: [Current timestamp]

### Progress Overview
| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Done | [X] | [X]% |
| 🟡 In Review | [X] | [X]% |
| 🔵 In Progress | [X] | [X]% |
| 🟢 Ready | [X] | [X]% |
| 🔴 Blocked | [X] | [X]% |
| ⚪ Backlog | [X] | [X]% |
| **Total** | **[X]** | **100%** |

### 🟢 Ready Queue (Prioritized by P-level, then by unblock count)
| ID | Title | Priority | Domain | Est | Unblocks |
|----|-------|----------|--------|-----|----------|
| [ID] | [Title] | P1 | backend | 2h | 3 issues |
| [ID] | [Title] | P2 | frontend | 4h | 1 issue |

### 🔵 Active Work
| ID | Title | Assignee | Started | 
|----|-------|----------|---------|
| [ID] | [Title] | [Name] | [Time] |

### 🔴 Blocked Items
| ID | Title | Blocked By | Blocker Status |
|----|-------|------------|----------------|
| [ID] | [Title] | [Blocker ID] | [In Progress] |

### ⚠️ Attention Required
- [List any stale items, circular dependencies, or escalations]

### Recommended Next Action
[Specific recommendation based on current state]
```

---

## OPERATION B: ASSIGN WORK

### Step 1: Get Ready Issues

```
TOOL: user-linear-list_issues
PARAMETERS:
  project: "[Project Name]"
  state: "Todo"
  limit: 50
```

### Step 2: Filter and Score

For each issue in `Todo` status:

1. **Check if truly ready**: Read description, look for "Blocked By". If blocked by incomplete issue, skip.

2. **Check capability match**: Does issue label/category match requester's capabilities?

3. **Score the issue**:
   ```
   Score = (Priority Score) + (Critical Path Bonus) + (Unblock Bonus) - (Age Penalty)
   
   Priority Score: P1=100, P2=80, P3=60, P4=40
   Critical Path Bonus: +50 if issue description mentions "critical path"
   Unblock Bonus: +10 per issue that lists this as blocker
   Age Penalty: -5 per day in Todo status
   ```

4. **Select highest scoring issue** that fits requester's time available

### Step 3: Assign the Task

```
TOOL: user-linear-update_issue
PARAMETERS:
  id: "[Selected Issue ID]"
  assignee: "[Requester name or 'me']"
  state: "In Progress"
```

```
TOOL: user-linear-create_comment
PARAMETERS:
  issueId: "[Selected Issue ID]"
  body: "Assigned by Orchestrator to [Requester]. Starting work."
```

### Step 4: Output Assignment

```markdown
## 🎯 Task Assignment

**Assigned To**: [Requester]
**Issue**: [ISSUE-ID] - [Title]
**Priority**: P[X]
**Estimated Time**: [X] hours
**Linear URL**: [URL]
**Project Branch**: `[project-branch]`

### Why This Task?
- [Reason 1: e.g., "Highest priority ready task"]
- [Reason 2: e.g., "Unblocks 3 other issues"]
- [Reason 3: e.g., "Matches backend capability"]

### Before Starting
1. ✅ Issue moved to "In Progress"
2. ⏳ Create issue branch from project branch: `[ISSUE-ID]-[short-description]` (base: `[project-branch]`)
3. ⏳ Read full issue description

### Execute With
Use `@.cursor/commands/execute-linear-task.md` with:
- Issue ID: [ISSUE-ID]
- Project branch: `[project-branch]` (created from `development`)

### On Completion
Report back with: "Completed [ISSUE-ID]" or "Blocked on [ISSUE-ID]: [reason]"
```

### If No Work Available

```markdown
## ℹ️ No Suitable Tasks Available

**Requester**: [Name]
**Capabilities**: [List]

### Reason
[Why no tasks match - e.g., "All backend tasks are blocked"]

### Suggestions
1. [Help unblock ISSUE-X by reviewing PR]
2. [Work on documentation while waiting]
3. [Investigate spike for ISSUE-Y]

### Currently Blocked Tasks Waiting On
| Blocked Task | Waiting For | Blocker Status |
|--------------|-------------|----------------|
| [ID] | [Blocker ID] | [In Progress - ETA 2h] |
```

---

## OPERATION C: REPORT PROGRESS

### For `completed` or `needs-review`:

```
TOOL: user-linear-update_issue
PARAMETERS:
  id: "[Issue ID]"
  state: "In Review"
```

Then analyze impact:

```
TOOL: user-linear-list_issues
PARAMETERS:
  project: "[Project Name]"
  limit: 100
```

Find issues that list the completed issue as a blocker. For each:
- Check if ALL their blockers are now done
- If yes, they become Ready

```markdown
## ✅ Task Completed: [ISSUE-ID]

### Status Update
- Issue moved to: In Review
- PR: [If provided]

### Impact Analysis
**Newly Unblocked** (all blockers now done):
| ID | Title | Priority | Now Ready |
|----|-------|----------|-----------|
| [ID] | [Title] | P[X] | ✅ Yes |

**Still Blocked** (has other incomplete blockers):
| ID | Title | Still waiting for |
|----|-------|-------------------|
| [ID] | [Title] | [Other blocker ID] |

### Updated Ready Queue
[Show top 5 ready items]

### Next Recommended Task
For [Requester] with [capabilities]:
→ [ISSUE-ID]: [Title] (P[X], just unblocked)

### Metrics
- Completed today: [X]
- Ready queue size: [X]
- Blocked queue size: [X]
```

### For `blocked`:

```
TOOL: user-linear-update_issue
PARAMETERS:
  id: "[Issue ID]"
  state: "Todo"
```

```
TOOL: user-linear-create_comment
PARAMETERS:
  issueId: "[Issue ID]"
  body: "## Blocked\n\n**Reason**: [User's notes]\n**Reported by**: Orchestrator\n**Time**: [Now]"
```

```markdown
## 🔴 Task Blocked: [ISSUE-ID]

### Blocker Details
**Issue**: [ISSUE-ID] - [Title]
**Reason**: [User's notes]
**Status Changed To**: Todo

### Resolution Analysis
[Analyze what's blocking and suggest resolution]

**Type**: [Dependency | Technical | External | Requirements]

### Recommended Actions
1. [Action 1]
2. [Action 2]

### Alternative Work Available
While waiting, [Requester] can work on:
| ID | Title | Priority | Domain |
|----|-------|----------|--------|
| [ID] | [Title] | P[X] | [Domain] |
```

### For `failed`:

```
TOOL: user-linear-create_comment
PARAMETERS:
  issueId: "[Issue ID]"
  body: "## Task Failed\n\n**Reason**: [User's notes]\n**Action Required**: [See orchestrator analysis]"
```

```markdown
## ❌ Task Failed: [ISSUE-ID]

### Failure Details
**Issue**: [ISSUE-ID] - [Title]
**Reason**: [User's notes]

### 🚨 ESCALATION REQUIRED

This requires human decision. Options:

1. **Retry**: Same person tries again with more context
2. **Reassign**: Different person with [specific expertise] takes over  
3. **Spike**: Create research task to investigate root cause
4. **Descope**: Remove from current milestone, revisit later

### Recommended Action
[Your recommendation based on failure reason]

### Human Decision Needed
Please respond with which option to take, or provide alternative direction.
```

---

## OPERATION D: PLAN SPRINT

### Step 1: Calculate Capacity

```
Total Capacity = [Duration days] × [Hours per day] × [Number of agents] × 0.7
(0.7 accounts for meetings, context switching, reviews)

Example: 5 days × 6 hours × 2 agents × 0.7 = 42 available hours
```

### Step 2: Query All Issues

```
TOOL: user-linear-list_issues
PARAMETERS:
  project: "[Project Name]"
  limit: 200
```

### Step 3: Prioritize for Sprint

1. **Must Have**: All P1 (Urgent) and P2 (High) ready issues
2. **Should Have**: P3 (Normal) issues on critical path
3. **Could Have**: Other P3 issues that fit remaining capacity
4. **Won't Have**: P4 and anything that doesn't fit

### Step 4: Generate Sprint Plan

```markdown
## 📅 Sprint Plan: [Date Range]

### Capacity Planning
| Resource | Hours Available | Allocated | Buffer |
|----------|-----------------|-----------|--------|
| [Agent 1] | [X]h | [X]h | [X]h |
| [Agent 2] | [X]h | [X]h | [X]h |
| **Total** | **[X]h** | **[X]h** | **[X]h** |

### Sprint Goals
1. [ ] [Primary goal]
2. [ ] [Secondary goal]  
3. [ ] [Tertiary goal]

### Committed Work
| ID | Title | Est | Assignee | Dependencies |
|----|-------|-----|----------|--------------|
| [ID] | [Title] | [X]h | [Name] | None |
| [ID] | [Title] | [X]h | [Name] | [ID] |

### Execution Order
**Day 1**: [ID], [ID] (foundation work)
**Day 2**: [ID], [ID] (parallel feature work)
**Day 3**: [ID] (integration)
...

### Parallel Opportunities
These issues can be worked simultaneously:
- [ID] (backend) + [ID] (frontend)
- [ID] (infra) + [ID] (docs)

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Medium | High | [Plan] |

### Not Included (Deprioritized)
| ID | Title | Reason |
|----|-------|--------|
| [ID] | [Title] | P4, not on critical path |
```

---

## OPERATION E: PREPARE PARALLEL WORK (LINEAR-FIRST)

(Phase B: LOX-1138.) Use this when you want to run the **parallel runner** (one worktree per issue, cursor-agent per worktree). The runner must be installed in the consumer repo first.

**Input**: Project name, project branch, optional issue IDs (or "next N ready").

### Step 1: Get ready issues (if issue IDs not provided)

```
TOOL: user-linear-list_issues
PARAMETERS:
  project: "[Project Name]"
  state: "Todo"
  limit: 50
```

For each issue, check description for "Blocked By". Exclude any that are blocked by an incomplete issue. Optionally take the first **N** (user-specified or default: all). Derive suggested branch name: `<ISSUE-ID>-linear` or from issue title slug.

### Step 2: Output table and runner command

Produce:

```markdown
## 🚀 Prepare parallel work: [Project Name]

**Project branch**: `[project-branch]`

### Ready issues (no blockers)
| Issue ID | Title | Suggested branch |
|----------|-------|------------------|
| [ID] | [Title] | [ID]-linear |
| ... | ... | ... |

### Run the parallel runner

1. **Install** (if not already installed): From your **consumer repo root** (the repo with your code and Linear work), run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/symmatiq/ralph-wiggum-linear-cursor/main/install.sh | bash
   ```
   This creates `.cursor/linear-ralph-scripts/` in that repo.

2. **Run** from the same repo root:
   ```bash
   ./.cursor/linear-ralph-scripts/linear-parallel-run.sh PROJECT_BRANCH=[project-branch] ISSUE_IDS="[ID1] [ID2] [ID3]"
   ```
   Example:
   ```bash
   ./.cursor/linear-ralph-scripts/linear-parallel-run.sh project/linear-first-parallel-runner "ISSUE-1 ISSUE-2 ISSUE-3"
   ```

3. **Optional**: `MAX_PARALLEL=3` (default), `INTEGRATION_BRANCH=...` to merge all into one branch, `--cleanup` to remove worktrees after.

**Docs**: See `.cursor/docs/parallel-linear-worktrees.md` in the consumer repo (if present) and the [ralph-wiggum-linear-cursor](https://github.com/symmatiq/ralph-wiggum-linear-cursor) README.
```

If the user provided specific **issue IDs**, use those in `ISSUE_IDS` instead of listing from Linear. Still output the same run instructions.

---

## ESCALATION TRIGGERS

Automatically escalate to human when:

1. **Circular Dependencies**: Issue A blocks B, B blocks A
2. **Stale Blockers**: Blocked for >48 hours without progress  
3. **Repeated Failures**: Same task fails twice
4. **Capacity Overflow**: More P1/P2 work than capacity
5. **Critical Path Risk**: Critical path items blocked

### Escalation Format

```markdown
## 🚨 ESCALATION REQUIRED

**Type**: [Type from above]
**Severity**: High
**Affected**: [List of issue IDs]

### Situation
[What's happening]

### Impact  
[What's blocked, business impact]

### Options
1. [Option A]: [Description, Pros, Cons]
2. [Option B]: [Description, Pros, Cons]

### Recommendation
[Your suggested path forward]

### Decision Needed By
[Urgency and deadline]
```

---

## WHAT TO DO NEXT

Based on operation completed:

| Operation | Next Step |
|-----------|-----------|
| Status Check | Assign work to available agents |
| Assign Work | Agent uses `execute-linear-task.md` |
| Completed Task | Assign next task or trigger PR review |
| Blocked Task | Resolve blocker or assign alternative |
| Sprint Plan | Begin execution with first ready task |
| Prepare parallel work | User runs `linear-parallel-run.sh` in consumer repo with printed ISSUE_IDS |

---

## REFERENCE

- **Create Project**: `@.cursor/commands/create-linear-project.md`
- **Execute Task**: `@.cursor/commands/execute-linear-task.md`
- **Review PR**: `@.cursor/commands/review-pull-request.md`
- **Linear Conventions**: `@.cursor/rules/linear-task-management.mdc`

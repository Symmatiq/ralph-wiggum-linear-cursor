# Create Linear Project from Plan (Initiative-as-Plan)

You are an expert project manager and technical architect. Transform a Cursor plan into a Linear hierarchy using **initiative-as-plan**: one Linear initiative per plan; projects and issues live on the **default team** (user provides team name or ID); **labels** (`frontend`, `backend`, domain) route work. No separate Frontend/Backend teams. See [.cursor/plans/linear_team_project_initiative_setup.plan.md](.cursor/plans/linear_team_project_initiative_setup.plan.md) if present.

---

## INPUT REQUIRED

Before proceeding, you MUST have:

1. **Source Plan**: A Cursor plan file (`.plan.md`) or detailed project description

Optional:

- **Initiative name override**: Name for the Linear initiative (default: use plan title)
- **Default team**: Team name or ID for all projects (user must provide or you must ask). Do not create or assume Frontend/Backend teams.
- **Split by work type**: If the plan has both frontend and backend work, create two projects "[Plan] – Backend" and "[Plan] – Frontend" on the default team (optional; otherwise one project per plan).

If Source Plan is missing, ASK the user. Do not assume or guess.

---

## STEP 1: Analyze the Plan

Read the provided plan completely. Extract and document:

```markdown
## Plan Analysis

### Project Overview
- **Goal**: [One sentence summary]
- **Success Criteria**: [How we know it's done]
- **Estimated Scope**: [Small/Medium/Large]

### Phases Identified
1. [Phase 1 Name] - [Brief description]
2. [Phase 2 Name] - [Brief description]
...

### Technical Domains (for labels and optional project split)
- [ ] Backend - [X items]  → label **backend** (and domain labels)
- [ ] Frontend - [X items] → label **frontend** (and domain labels)
- [ ] Infrastructure - [X items] → label **backend**
- [ ] DevOps - [X items] → label **backend**

### Work split for routing
- Backend work: [X] items → issues get label `backend` (and optionally `streaming` / `agents` / `api` / `tooling`, domain)
- Frontend work: [X] items → issues get label `frontend` (and domain)
- If both > 0 and user wants split: create two projects "[Plan] – Backend", "[Plan] – Frontend" on default team. Else: one project "[Plan name]".

### Dependencies Found
- [Item A] must complete before [Item B]
- [Item C] must complete before [Item D, Item E]
- Note cross-area blockers (e.g. frontend task X blocked by backend task Y)

### Subtask breakdown (for STEP 5)
- For each phase, list **small subtasks** (one issue each), not one issue per plan bullet. Example: Phase 1 "Migration" → subtasks: (1) Add getConnectionForPipeline helper, (2) Update webhook call site, (3) Update nodes/GET call site, (4) Update pipeline CRUD/export/import, (5) Optional S3 script, (6) Frontend pipeline.json + resolve-by-pipeline_id. If a plan subsection has 4+ distinct deliverables, list each as a separate subtask.

### Risks/Unknowns
- [Risk 1]: [Description]
- [Risk 2]: [Description]
```

---

## STEP 2: Initiative = the Plan

**Initiative-as-plan:** One Linear initiative represents this plan. All projects and issues from this plan attach to it.

- **Initiative name**: Plan title (or user-provided override). Use when creating projects.
- When creating each project, pass `initiative: "[Initiative name]"` so Linear associates the project with that initiative.

Document the **initiative name** for all project creation and the output summary.

---

## STEP 3: Create Projects (on Default Team, One or Two)

**Default team** = user-provided team name or ID. Ask if not provided. No Frontend/Backend teams.

From Plan Analysis:

- **One project (default):** Create **"[Initiative name]"** on the default team.
  - team: **[Default team]** (from user input)
  - initiative: **[Initiative name]**
  - description: [2–3 sentence summary from plan analysis]
  - All issues go in this project; each issue gets labels `frontend` or `backend` (and domain) for routing.

- **Two projects (optional, when plan has both FE and BE work):**
  - **"[Initiative name] – Backend"** on default team, same initiative. Backend/Infra/DevOps issues go here; still add label `backend` on issues.
  - **"[Initiative name] – Frontend"** on default team, same initiative. Frontend issues go here; still add label `frontend` on issues.

Use Linear MCP `create_project` with `name`, `team` (the default team name/ID), `initiative`, `description`, `state: "planned"`.

Document each created project ID for creating epics and issues.

---

## STEP 4: Create Epics (in the Correct Project)

For each major phase, assign it to the project that matches the work (one project → one epic per phase; two projects → epics in "[Plan] – Backend" or "[Plan] – Frontend" by phase domain). Create the epic in that **project**.

```
TOOL: user-linear-create_issue
PARAMETERS:
  title: "[Phase #]: [Phase Name]"
  team: "[Default team]"
  project: "[Initiative name]" OR "[Initiative name] – Backend" OR "[Initiative name] – Frontend"
  description: |
    ## Epic Scope
    [What this epic delivers]
    ## Acceptance Criteria
    - [ ] [Criteria 1]
    - [ ] [Criteria 2]
    ## Dependencies
    - Depends on: [Other epics if any]
    - Enables: [What this unblocks]
  labels: ["epic", "backend"] OR ["epic", "frontend"] (and domain as needed)
```

---

## STEP 5: Create Issues (in the Correct Project, Labels for Routing)

For each **subtask** (see granularity rules below), assign it to **Backend** or **Frontend**. Create the issue in the matching project. **Always** add labels:

- **Capability:** `backend` or `frontend` (and optionally `streaming`, `agents`, `api`, `tooling`)
- **Domain:** e.g. `dataproducts`, `billing`, `pipelines`, `governance` when useful

### Subtask granularity (MUST FOLLOW — smaller subtasks, not plan-bullet-sized)

**Always break work into small, single-responsibility issues.** One plan bullet or subsection often becomes **multiple** Linear issues.

- **One issue = one discrete deliverable.** Examples: one issue = "Add getConnectionForPipeline helper"; a separate issue = "Update webhook validation to use getConnectionForPipeline"; another = "Update nodes/GET to use getConnectionForPipeline"; another = "Optional S3 script to strip legacy connection_id"; another = "Frontend pipeline.json and resolve connection by pipeline_id."
- **Do not** group "helper + all call sites + S3 script + frontend" into a single issue. Split by: (1) helper, (2) each logical group of call sites or each major call site, (3) optional script, (4) frontend schema/API usage.
- **Do not** group "WebSocket route + $connect + sendMessage + IAM" into one issue unless each is trivial. Prefer: one issue for $connect auth, one for sendMessage handler + postToConnection, one for CDK/route + IAM if needed.
- **Do not** group "schema context builder + script + script-loader + chat handler injection" into one issue. Split: (1) buildEntitySchemaContext(), (2) studio-flows.md content, (3) script-loader registration, (4) chat handler injection.
- **Rule of thumb:** If the "Requirements" or "Technical Approach" list has more than 3–4 distinct deliverables or file areas, split into multiple issues. Each issue should be completable in one focused session (< 4 hours) and touch a small set of files (≤ 10, prefer 3–5).

### Sizing Rules (MUST FOLLOW)
- **< 4 hours** of focused work per issue
- **≤ 10 files** modified per issue (prefer 3-5)
- **Testable** in isolation
- **Self-contained** – includes all context needed
- **One discrete deliverable per issue** – when in doubt, split into more issues (see Subtask granularity above)

### Issue Template

```
TOOL: user-linear-create_issue
PARAMETERS:
  title: "[Concise action-oriented title]"
  team: "[Default team]"
  project: "[Initiative name]" OR "[Initiative name] – Backend" OR "[Initiative name] – Frontend"
  parentId: "[Epic ID if applicable]"
  priority: [0-4]
  labels: ["backend"|"frontend", "feature"|"bug"|"chore"|"spike"|"docs", "dataproducts"|"billing"|... as needed]
  description: |
    ## Context
    **Parent Epic**: [Epic title and ID]
    **Blocked By**: [Issue IDs or "None - Ready to Start"]
    **Unblocks**: [Issue IDs this enables]
    ## Objective
    [One sentence: what does "done" look like]
    ## Requirements
    - [ ] [Specific, testable requirement 1]
    - [ ] [Specific, testable requirement 2]
    ## Technical Approach
    **Category**: [Backend | Frontend | Infrastructure | DevOps]
    **Files to Modify**:
    - path/to/file - [create|modify] - [what changes]
    **Patterns to Follow**: [Reference existing code pattern]
    ## Test Plan
    - [ ] Unit: [specific test]
    - [ ] Integration: [if applicable]
    ## Agent Instructions
    1. [First action to take]
    2. If blocked: Report to orchestrator with details
```

### Priority Guide
- **1 (Urgent)**: Foundational, blocks 3+ other tasks
- **2 (High)**: On critical path, blocks 1-2 tasks
- **3 (Normal)**: Standard feature work
- **4 (Low)**: Nice-to-have, polish, can defer

### Cross-project dependencies
When a frontend issue is blocked by a backend issue (or vice versa), set **Blocked By** on the blocked issue to the blocking issue's ID. Linear supports cross-project issue links.

---

## STEP 6: Set Dependencies

After creating all issues, set blocking relationships (including across projects):

- Use Linear's "Blocked by" / "Blocks" when available via MCP.
- For cross-project: put "Blocked By: [ISSUE-ID]" in the description of the blocked issue if needed.

---

## STEP 7: Generate Output Summary

After creating all entities, produce this summary:

```markdown
## Linear Project Created (Initiative-as-Plan)

**Initiative**: [Initiative name] (the plan)
**Team**: [Default team]
**Projects**:
- [Initiative name] – [Linear URL] (if single project)
- [Initiative name] – Backend – [Linear URL] (if created)
- [Initiative name] – Frontend – [Linear URL] (if created)

**Total**: [X] Epics, [Y] Issues

### Hierarchy
Initiative: [Initiative name]
├── Project: [Initiative name] [ or – Backend / – Frontend ]
│   ├── Epic: [Epic 1] ([X] issues)
│   │   ├── [ISSUE-ID] [Title] - P[X] - [READY | blocked by ISSUE-ID] - labels: backend|frontend, ...
│   │   └── ...
│   └── ...
└── ...

### Ready Queue by Label
**backend (no blockers):**
1. [ISSUE-ID] [Title] - P[X]
**frontend (no blockers):**
1. [ISSUE-ID] [Title] - P[X]

### Critical Path
[ISSUE-A] → [ISSUE-B] → [ISSUE-C] …
Minimum completion time: ~[X] hours

### Next Steps
1. Run orchestrator filtered by project "[Initiative name]" and label "backend" or "frontend" as needed.
2. Or run execute-linear-task with issue ID: [First ready issue ID]
```

---

## WHAT TO DO NEXT

1. **Start work**: Use `@.cursor/commands/orchestrate-linear-work.md` with project name and/or label filter (e.g. label `backend`, `frontend`).
2. **Or execute directly**: Use `@.cursor/commands/execute-linear-task.md` with issue ID from the ready queue.

---

## ERROR HANDLING

### If Linear MCP fails
1. Report the error to the user.
2. Provide issue/epic/project details in markdown so the user can create them manually.
3. Ask for issue IDs if the user creates them manually.

### If plan is ambiguous
1. List unclear items.
2. Ask clarifying questions.
3. Do not guess requirements.

### If dependencies are circular
1. Identify the cycle.
2. Report to the user.
3. Suggest splitting a task to break the cycle.

---

## REFERENCE

- **Linear setup (projects + labels + initiatives, no teams)**: [.cursor/plans/linear_team_project_initiative_setup.plan.md](.cursor/plans/linear_team_project_initiative_setup.plan.md)
- **Orchestrator**: `@.cursor/commands/orchestrate-linear-work.md`
- **Execute Task**: `@.cursor/commands/execute-linear-task.md`
- **Review PR**: `@.cursor/commands/review-pull-request.md`

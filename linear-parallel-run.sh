#!/usr/bin/env bash
# Linear-first parallel runner: one worktree per issue, cursor-agent per worktree. (LOX-1130, LOX-1131, LOX-1132)
# Run from repo root. Requires: PROJECT_BRANCH, ISSUE_IDS (env or args).
# Optional: MAX_PARALLEL (default 3), INTEGRATION_BRANCH, --cleanup.

set -e

CLEANUP=false
# Parse --cleanup
for arg in "$@"; do
  if [[ "$arg" == "--cleanup" ]]; then
    CLEANUP=true
    break
  fi
done

# Script dir and repo root (script lives at .cursor/linear-ralph-scripts/linear-parallel-run.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKTREE_BASE="${LINEAR_RALPH_WORKTREE_BASE:-$REPO_ROOT/../.worktrees}"
LOG_DIR="${REPO_ROOT}/.cursor/linear-ralph-scripts/.logs"
PROMPT_FILE="${SCRIPT_DIR}/prompts/linear-execute-single-issue.md"

# Required: PROJECT_BRANCH, ISSUE_IDS (space-separated). Env wins; else first arg = branch, rest = issue IDs.
PROJECT_BRANCH="${PROJECT_BRANCH:-$1}"
if [[ -z "$ISSUE_IDS" ]]; then
  # Only shift if we consumed $1 as PROJECT_BRANCH (so first arg isn't an issue ID)
  [[ "$PROJECT_BRANCH" == "$1" ]] && shift
  ISSUE_IDS="$*"
fi
if [[ -z "$PROJECT_BRANCH" || -z "$ISSUE_IDS" ]]; then
  echo "Usage: PROJECT_BRANCH=<branch> ISSUE_IDS=\"<id1> <id2> ...\" [MAX_PARALLEL=3] [INTEGRATION_BRANCH=<branch>] [--cleanup] $0" >&2
  echo "Example: PROJECT_BRANCH=project/studio-ide ISSUE_IDS=\"LOX-123 LOX-124\" ./$0" >&2
  exit 1
fi

MAX_PARALLEL="${MAX_PARALLEL:-3}"

# Ensure we're in repo root for git ops
cd "$REPO_ROOT"

# ---- Validate ----
if ! command -v cursor-agent &>/dev/null; then
  echo "Error: cursor-agent not found on PATH. Install with: curl https://cursor.com/install -fsS | bash" >&2
  exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Error: Prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

echo "Fetching origin..."
git fetch origin

# Ensure PROJECT_BRANCH exists (local or remote); create from development if missing
if ! git rev-parse --verify "$PROJECT_BRANCH" &>/dev/null && ! git rev-parse --verify "origin/$PROJECT_BRANCH" &>/dev/null; then
  echo "Creating project branch $PROJECT_BRANCH from development..."
  git checkout development
  git pull origin development
  git checkout -b "$PROJECT_BRANCH"
  git push -u origin "$PROJECT_BRANCH"
else
  git checkout "$PROJECT_BRANCH"
  git pull origin "$PROJECT_BRANCH" || true
fi

mkdir -p "$WORKTREE_BASE" "$LOG_DIR"

# ---- Helpers (LOX-1131: cursor-agent invocation, prompt substitution, MAX_PARALLEL) ----
run_agent() {
  local issue_id="$1"
  local branch_name="${issue_id}-linear"
  local worktree_path="$WORKTREE_BASE/$issue_id"
  local log_file="$LOG_DIR/${issue_id}.log"

  (
    cd "$worktree_path"
    sed "s/{{ISSUE_ID}}/$issue_id/g; s/{{PROJECT_BRANCH}}/$PROJECT_BRANCH/g" "$PROMPT_FILE" \
      | cursor-agent -p --force --output-format stream-json >> "$log_file" 2>&1
    exit $?
  )
  local ex=$?
  echo $ex > "$LOG_DIR/${issue_id}.exit"
  return $ex
}

# ---- Create branches and worktrees for each issue ----
for issue_id in $ISSUE_IDS; do
  issue_id="${issue_id//,/}"
  [[ -z "$issue_id" ]] && continue
  branch_name="${issue_id}-linear"
  worktree_path="$WORKTREE_BASE/$issue_id"

  if [[ -d "$worktree_path" ]]; then
    echo "Worktree exists: $worktree_path (ensuring branch $branch_name)"
    (cd "$worktree_path" && git fetch origin && git checkout "$branch_name" 2>/dev/null || git checkout -b "$branch_name") || true
    continue
  fi

  git checkout "$PROJECT_BRANCH"
  git pull origin "$PROJECT_BRANCH" 2>/dev/null || true
  if ! git rev-parse --verify "$branch_name" &>/dev/null; then
    git checkout -b "$branch_name"
  else
    git checkout "$branch_name"
  fi
  git worktree add "$worktree_path" "$branch_name"
  echo "Created worktree $worktree_path -> $branch_name"
done

# ---- Run cursor-agent in parallel (batches of MAX_PARALLEL) ----
issues_array=()
for issue_id in $ISSUE_IDS; do
  issue_id="${issue_id//,/}"
  [[ -z "$issue_id" ]] && continue
  issues_array+=( "$issue_id" )
done

total=${#issues_array[@]}
for (( i=0; i<total; i+=MAX_PARALLEL )); do
  batch=( "${issues_array[@]:i:MAX_PARALLEL}" )
  for issue_id in "${batch[@]}"; do
    ( run_agent "$issue_id"; ) &
  done
  wait
done

# ---- Results table ----
echo ""
echo "Issue ID      | Worktree path           | Branch           | Status | Log"
echo "--------------+-------------------------+------------------+--------+------------------"
for issue_id in "${issues_array[@]}"; do
  branch_name="${issue_id}-linear"
  worktree_path="$WORKTREE_BASE/$issue_id"
  exit_file="$LOG_DIR/${issue_id}.exit"
  log_file="$LOG_DIR/${issue_id}.log"
  if [[ -f "$exit_file" ]]; then
    code=$(cat "$exit_file")
    if [[ "$code" == "0" ]]; then status="ok"; else status="fail"; fi
  else
    status="?"
  fi
  printf "%-13s | %-23s | %-16s | %-6s | %s\n" "$issue_id" "$worktree_path" "$branch_name" "$status" "$log_file"
done

# ---- Optional: merge into integration branch (LOX-1132: INTEGRATION_BRANCH + --cleanup) ----
if [[ -n "$INTEGRATION_BRANCH" ]]; then
  echo ""
  echo "Merging issue branches into $INTEGRATION_BRANCH..."
  git checkout "$PROJECT_BRANCH"
  git pull origin "$PROJECT_BRANCH" 2>/dev/null || true
  if ! git rev-parse --verify "$INTEGRATION_BRANCH" &>/dev/null; then
    git checkout -b "$INTEGRATION_BRANCH"
  else
    git checkout "$INTEGRATION_BRANCH"
    git pull origin "$INTEGRATION_BRANCH" 2>/dev/null || true
  fi
  for issue_id in "${issues_array[@]}"; do
    branch_name="${issue_id}-linear"
    echo "  Merging $branch_name..."
    git merge --no-edit "$branch_name" || echo "  Warning: merge conflict in $branch_name"
  done
  git push -u origin "$INTEGRATION_BRANCH" 2>/dev/null || git push origin "$INTEGRATION_BRANCH"
  echo "Integration branch: $INTEGRATION_BRANCH (push done). Open a single PR from $INTEGRATION_BRANCH to $PROJECT_BRANCH."
fi

# ---- Optional: cleanup worktrees ----
if [[ "$CLEANUP" == "true" ]]; then
  echo ""
  echo "Cleaning up worktrees..."
  for issue_id in "${issues_array[@]}"; do
    worktree_path="$WORKTREE_BASE/$issue_id"
    if [[ -d "$worktree_path" ]]; then
      git worktree remove "$worktree_path" --force 2>/dev/null || true
      echo "  Removed $worktree_path"
    fi
  done
fi

echo ""
echo "Done. Inspect logs under $LOG_DIR if needed."

#!/usr/bin/env bash
# Install Linear-first parallel runner into the current repo. (LOX-1128)
# Usage: curl -fsSL https://raw.githubusercontent.com/symmatiq/ralph-wiggum-linear-cursor/main/install.sh | bash
# Idempotent: safe to run multiple times.

set -e

INSTALL_DIR=".cursor/linear-ralph-scripts"
PROMPTS_DIR="${INSTALL_DIR}/prompts"
LOGS_DIR="${INSTALL_DIR}/.logs"
BASE_URL="${RALPH_LINEAR_INSTALL_BASE:-https://raw.githubusercontent.com/symmatiq/ralph-wiggum-linear-cursor/main}"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Error: Not inside a git repository. Run this from your project root." >&2
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
mkdir -p "$PROMPTS_DIR" "$LOGS_DIR"

fetch() {
  local path="$1"
  local dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "${BASE_URL}/${path}" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -q -O "$dest" "${BASE_URL}/${path}"
  else
    echo "Error: need curl or wget to install." >&2
    exit 1
  fi
}

echo "Installing ralph-wiggum-linear-cursor into ${ROOT}/${INSTALL_DIR}..."
fetch "linear-parallel-run.sh" "${INSTALL_DIR}/linear-parallel-run.sh"
fetch "prompts/linear-execute-single-issue.md" "${PROMPTS_DIR}/linear-execute-single-issue.md"
chmod +x "${INSTALL_DIR}/linear-parallel-run.sh"

# Optional: install Cursor Agent Skills for consistent pre-flight, submit, and worktree behavior
if [[ -n "${INSTALL_SKILLS:-}" ]]; then
  SKILLS_DIR="${ROOT}/.cursor/skills"
  mkdir -p "${SKILLS_DIR}/linear-pre-flight" "${SKILLS_DIR}/linear-submit" "${SKILLS_DIR}/linear-worktree-mode" "${SKILLS_DIR}/execute-linear-task"
  fetch ".cursor/skills/linear-pre-flight/SKILL.md" "${SKILLS_DIR}/linear-pre-flight/SKILL.md"
  fetch ".cursor/skills/linear-submit/SKILL.md" "${SKILLS_DIR}/linear-submit/SKILL.md"
  fetch ".cursor/skills/linear-worktree-mode/SKILL.md" "${SKILLS_DIR}/linear-worktree-mode/SKILL.md"
  fetch ".cursor/skills/execute-linear-task/SKILL.md" "${SKILLS_DIR}/execute-linear-task/SKILL.md"
  echo "Installed Linear execution skills into ${SKILLS_DIR}."
fi

echo "Done. Run from repo root:"
echo "  ./${INSTALL_DIR}/linear-parallel-run.sh PROJECT_BRANCH=<branch> ISSUE_IDS=\"<id1> <id2> ...\""
echo "Example:"
echo "  ./${INSTALL_DIR}/linear-parallel-run.sh project/studio-ide \"LOX-123 LOX-124\""
if [[ -z "${INSTALL_SKILLS:-}" ]]; then
  echo "Optional: INSTALL_SKILLS=1 to install Linear execution skills into .cursor/skills/ for more consistent agent behavior."
fi

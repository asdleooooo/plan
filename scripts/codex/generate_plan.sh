#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <ticket_id> <requirements_path> <ui_path> [review_feedback_file]" >&2
  exit 1
fi

ticket_id="$1"
requirements_path="$2"
ui_path="$3"
review_feedback_file="${4:-}"

plan_dir="plans/${ticket_id}"
history_dir="${plan_dir}/plan_history"
plan_file="${plan_dir}/plan.md"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "${history_dir}"

if [[ -f "${plan_file}" ]]; then
  cp "${plan_file}" "${history_dir}/plan_${timestamp}.md"
fi

feedback_section=""
if [[ -n "${review_feedback_file}" && -f "${review_feedback_file}" ]]; then
  feedback_section+=$'\n## Review Feedback\n\n```text\n'
  feedback_section+="$(cat "${review_feedback_file}")"
  feedback_section+=$'\n```\n'
fi

cat > "${plan_file}" <<EOF
# Plan for ${ticket_id}

## Inputs
- Requirements: ${requirements_path}
- UI spec: ${ui_path}
- Generated at (UTC): ${timestamp}

## Objective
- Deliver a minimal, testable implementation aligned with requirements and UI constraints.

## Execution Steps
1. Read requirement and UI context.
2. Break work into small implementation tasks.
3. Implement task-by-task with narrow commits.
4. Run \`npm run verify\` and fix failures.
5. Publish progress and risks.

## Deliverables
- Code changes for ${ticket_id}
- Updated tests where needed
- \`plans/${ticket_id}/execution_report.md\`
${feedback_section}
EOF

echo "Generated ${plan_file}"

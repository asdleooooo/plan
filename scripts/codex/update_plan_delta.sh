#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <ticket_id> [review_feedback_file]" >&2
  exit 1
fi

ticket_id="$1"
review_feedback_file="${2:-}"
plan_dir="plans/${ticket_id}"
plan_file="${plan_dir}/plan.md"
delta_file="${plan_dir}/plan_delta.md"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

if [[ ! -f "${plan_file}" ]]; then
  echo "Missing plan file: ${plan_file}" >&2
  exit 1
fi

mkdir -p "${plan_dir}"

cat > "${delta_file}" <<EOF
# Plan Delta for ${ticket_id}

Generated at (UTC): ${timestamp}

## Delta Summary
- Updated execution focus based on latest review feedback.
- This file should be refreshed before each implementation loop.

## Impacted Plan Areas
- Scope and priorities
- Test focus
- Risk mitigations

EOF

if [[ -n "${review_feedback_file}" && -f "${review_feedback_file}" ]]; then
  cat >> "${delta_file}" <<EOF
## Review Feedback Snapshot

\`\`\`text
$(cat "${review_feedback_file}")
\`\`\`
EOF
fi

echo "Generated ${delta_file}"

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
report_file="${plan_dir}/execution_report.md"
max_retries="${VERIFY_MAX_RETRIES:-2}"

if [[ ! -f "${plan_file}" ]]; then
  echo "Missing plan file: ${plan_file}" >&2
  exit 1
fi

scripts/codex/generate_tests.sh

attempt=0
status="failed"
while (( attempt <= max_retries )); do
  attempt=$((attempt + 1))
  echo "verify attempt ${attempt}/${max_retries}..."
  if npm run verify; then
    status="passed"
    break
  fi
  echo "verify failed on attempt ${attempt}"
  if (( attempt <= max_retries )); then
    echo "retrying verify..."
  fi
done

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "${plan_dir}"

cat > "${report_file}" <<EOF
# Execution Report for ${ticket_id}

Generated at (UTC): ${timestamp}

## Inputs
- Plan: plans/${ticket_id}/plan.md
- Review feedback file: ${review_feedback_file:-N/A}

## Verification
- Status: ${status}
- Attempts: ${attempt}
- Max retries: ${max_retries}

## Traceability
- Review comment IDs: ${REVIEW_COMMENT_IDS:-N/A}
- Commit SHA: ${GITHUB_SHA:-N/A}
- Impacted plan items: follow-up required by implementer
EOF

if [[ "${status}" != "passed" ]]; then
  echo "Verification failed after ${attempt} attempts" >&2
  exit 2
fi

echo "Generated ${report_file}"

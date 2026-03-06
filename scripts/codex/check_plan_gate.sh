#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <ticket_id> [strategy]" >&2
  exit 1
fi

ticket_id="$1"
strategy="${2:-label}"
required_label="${PLAN_REQUIRED_LABEL:-plan-approved}"
labels="${PLAN_LABELS:-}"
approved_reviews="${APPROVED_REVIEW_COUNT:-0}"

if [[ "${strategy}" == "label" ]]; then
  if echo ",${labels}," | grep -q ",${required_label},"; then
    echo "Plan gate passed for ${ticket_id}: label '${required_label}' exists."
    exit 0
  fi
  echo "Plan gate failed for ${ticket_id}: missing label '${required_label}'." >&2
  exit 2
fi

if [[ "${strategy}" == "review" ]]; then
  if [[ "${approved_reviews}" =~ ^[0-9]+$ ]] && (( approved_reviews >= 1 )); then
    echo "Plan gate passed for ${ticket_id}: approved reviews=${approved_reviews}."
    exit 0
  fi
  echo "Plan gate failed for ${ticket_id}: approved reviews=${approved_reviews}." >&2
  exit 2
fi

echo "Unsupported strategy: ${strategy}. Use label|review." >&2
exit 1

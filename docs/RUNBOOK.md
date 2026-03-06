# Runbook

## 1. Submit requirement/UI
1. Add requirement doc to `docs/requirements/<ticket_id>.md`.
2. Add UI material to `docs/ui/<ticket_id>/`.

## 2. Generate/iterate plan
1. Trigger workflow `codex-plan-loop` with `ticket_id`.
2. Review plan PR (`plan/<ticket_id>`).
3. Add comments and iterate with `/codex-plan <ticket_id>`.
4. Add label `plan-approved` when ready.

## 3. Execute/iterate implementation
1. Trigger workflow `codex-implement-loop` with `ticket_id`.
2. Review implementation PR (`feat/<ticket_id>`).
3. Add comments and iterate with `/codex-impl <ticket_id>`.
4. Add label `code-approved` after review.

## 4. Merge conditions
- Required checks green: `verify`, `plan-gate`, `impl-gate`
- Required labels present on implementation PR:
  - `plan-approved`
  - `code-approved`

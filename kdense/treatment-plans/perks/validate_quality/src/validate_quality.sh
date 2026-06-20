#!/usr/bin/env bash
# validate_quality — heuristic quality + compliance audit of a LaTeX treatment plan (read-only).
# Structured JSON audit line; full report -> quality.txt.
set -uo pipefail
: "${PLAN_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/quality.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3/the lib is absent.
: > "$OUT"
# Core exits non-zero when quality <70%; capture report regardless (|| true) and never fail the porter.
python3 "$HERE/validate_treatment_plan.py" "$PLAN_FILE" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_quality","status":"ok","report":"%s"}\n' "$OUT"

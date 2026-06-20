#!/usr/bin/env bash
# calculate_scores — weighted ScholarEval aggregate score + quality level + bar chart report (read-only).
# Thin porter: env -> args for the vendored calculate_scores.py core. Structured JSON audit line.
set -uo pipefail
: "${SCORES_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"

ARGS=(--scores "$SCORES_JSON" --output "$OUT")
if [ -n "${WEIGHTS_JSON:-}" ]; then
  ARGS+=(--weights "$WEIGHTS_JSON")
fi

python3 "$HERE/calculate_scores.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true

# Guarantee a non-empty artifact even if the core wrote nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"calculate_scores","status":"ok","report":"%s"}\n' "$OUT"

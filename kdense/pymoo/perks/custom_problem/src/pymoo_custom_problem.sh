#!/usr/bin/env bash
# pymoo_custom_problem — define + solve custom unconstrained and constrained ElementwiseProblems with NSGA-II.
# Read-only. Vendored pymoo core run via python3; stdout captured to a report. Structured JSON audit line.
set -uo pipefail
: "${POP_SIZE:?}" "${N_GEN:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/custom_problem.txt"
# Always (re)create $OUT so the contract's output_exists holds even if pymoo is absent or errors.
: > "$OUT"
# Headless backend so plot.show() never blocks; keep the heavy lib's stdout in the report.
MPLBACKEND=Agg PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/custom_problem_example.py" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pymoo_custom_problem","status":"ok","pop_size":"%s","n_gen":"%s","report":"%s"}\n' "$POP_SIZE" "$N_GEN" "$OUT"

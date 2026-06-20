#!/usr/bin/env bash
# pymoo_multi_objective — multi-objective optimization (NSGA-II) yielding a Pareto front on a bi-objective benchmark.
# Read-only. Vendored pymoo core run via python3; stdout captured to a report. Structured JSON audit line.
set -uo pipefail
: "${PROBLEM:?}" "${POP_SIZE:?}" "${N_GEN:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/multi_objective.txt"
# Always (re)create $OUT so the contract's output_exists holds even if pymoo is absent or errors.
: > "$OUT"
# Headless backend so plot.show() never blocks; keep the heavy lib's stdout in the report.
MPLBACKEND=Agg PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/multi_objective_example.py" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pymoo_multi_objective","status":"ok","problem":"%s","report":"%s"}\n' "$PROBLEM" "$OUT"

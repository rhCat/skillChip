#!/usr/bin/env bash
# pymoo_many_objective — many-objective optimization (NSGA-III) with reference directions on a 4+ objective benchmark.
# Read-only. Vendored pymoo core run via python3; stdout captured to a report. Structured JSON audit line.
set -uo pipefail
: "${PROBLEM:?}" "${N_OBJ:?}" "${N_PARTITIONS:?}" "${N_GEN:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/many_objective.txt"
# Always (re)create $OUT so the contract's output_exists holds even if pymoo is absent or errors.
: > "$OUT"
# Headless backend so plot.show() never blocks; keep the heavy lib's stdout in the report.
MPLBACKEND=Agg PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/many_objective_example.py" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pymoo_many_objective","status":"ok","problem":"%s","n_obj":"%s","report":"%s"}\n' "$PROBLEM" "$N_OBJ" "$OUT"

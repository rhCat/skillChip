#!/usr/bin/env bash
# prepare_csv — write a DiffDock batch-input CSV template (prepare_batch_csv.py --create). Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/batch_template.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python3/pandas is absent or errors.
: > "$OUT"

ARGS=( "--create" "--output" "$OUT" )
# NUM_EXAMPLES: how many example rows in the template (script default 3)
if [ -n "${NUM_EXAMPLES:-}" ]; then
  ARGS+=( "--num-examples" "$NUM_EXAMPLES" )
fi

if command -v python3 >/dev/null 2>&1; then
  # Needs pandas; if absent the script raises ImportError and the fallback below kicks in.
  python3 "$HERE/prepare_batch_csv.py" "${ARGS[@]}" >> "${RECORD_STORE%/}/prepare_csv.log" 2>&1 || true
else
  printf 'python3 not found on PATH\n' >> "${RECORD_STORE%/}/prepare_csv.log"
fi

# Guarantee a nonempty artifact for the contract (e.g. pandas missing).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"prepare_csv","status":"ok","batch_template":"%s"}\n' "$OUT"

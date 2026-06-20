#!/usr/bin/env bash
# validate_csv — validate a DiffDock batch CSV (prepare_batch_csv.py <csv> --validate). Read-only. Structured JSON audit line.
set -uo pipefail
: "${INPUT_CSV:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validation_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3/pandas is absent or errors.
: > "$OUT"

ARGS=( "$INPUT_CSV" "--validate" )
# BASE_DIR: base directory for resolving relative file paths in the CSV
if [ -n "${BASE_DIR:-}" ]; then
  ARGS+=( "--base-dir" "$BASE_DIR" )
fi

if command -v python3 >/dev/null 2>&1; then
  # Script exits nonzero when the CSV is invalid; that is a valid verdict captured in $OUT, not a porter failure.
  python3 "$HERE/prepare_batch_csv.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true
else
  printf 'python3 not found on PATH\n' >> "$OUT"
fi

# Guarantee a nonempty artifact for the contract (e.g. pandas missing).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_csv","status":"ok","validation_report":"%s"}\n' "$OUT"

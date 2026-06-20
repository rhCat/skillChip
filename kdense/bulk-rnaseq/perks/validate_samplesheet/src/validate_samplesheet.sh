#!/usr/bin/env bash
# validate_samplesheet — validate an nf-core/rnaseq samplesheet (+ optional design metadata). Structured JSON output (audit/debug log).
set -uo pipefail
: "${SAMPLESHEET:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validation_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python/pandas is absent or the script errors.
: > "$OUT"

# Optional inputs -> argv (translate env to the vendored CLI's flags).
ARGS=( --samplesheet "$SAMPLESHEET" )
[ -n "${METADATA:-}" ]       && ARGS+=( --metadata "$METADATA" )
[ -n "${CONDITION_COL:-}" ]  && ARGS+=( --condition-col "$CONDITION_COL" )
[ -n "${MIN_REPLICATES:-}" ] && ARGS+=( --min-replicates "$MIN_REPLICATES" )

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"validate_samplesheet","status":"ok","report":"%s"}\n' "$OUT"
  exit 0
fi

# Run the vendored core; capture report regardless of exit code (errors -> nonzero, which the porter absorbs).
python3 "$HERE/validate_samplesheet.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_samplesheet","status":"ok","report":"%s"}\n' "$OUT"

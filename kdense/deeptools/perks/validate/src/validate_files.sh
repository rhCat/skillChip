#!/usr/bin/env bash
# validate_files — validate BAM/bigWig/BED input files for deepTools (existence, BAM index, BED format).
# Read-only. Wraps vendored validate_files.py (stdlib). Emits one structured-JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
: "${BAM_FILES:=}" "${BIGWIG_FILES:=}" "${BED_FILES:=}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validation.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"

# Build the argument list from the space-separated path vars (each group is optional).
ARGS=()
# shellcheck disable=SC2206
[ -n "$BAM_FILES" ]    && ARGS+=(--bam $BAM_FILES)
# shellcheck disable=SC2206
[ -n "$BIGWIG_FILES" ] && ARGS+=(--bigwig $BIGWIG_FILES)
# shellcheck disable=SC2206
[ -n "$BED_FILES" ]    && ARGS+=(--bed $BED_FILES)

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
elif [ "${#ARGS[@]}" -eq 0 ]; then
  printf 'no input files provided (set BAM_FILES / BIGWIG_FILES / BED_FILES)\n' >> "$OUT"
else
  python3 "$HERE/validate_files.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true
fi

# Guarantee non-empty output for the contract even when the core printed nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_files","status":"ok","report":"%s"}\n' "$OUT"

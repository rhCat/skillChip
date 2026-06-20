#!/usr/bin/env bash
# extract_chromatograms — TIC/BPC/XIC traces -> tidy CSV (+ optional PNG plot). JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/chromatograms.csv"
PLOT="${RECORD_STORE%/}/chromatograms.png"
LOG="${RECORD_STORE%/}/extract_chromatograms.log"
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" --out "$OUT")
# default to TIC if no trace requested, so the core does not error out
if [ "${TIC:-}" != "1" ] && [ "${BPC:-}" != "1" ] && [ -z "${MZ:-}" ]; then
  ARGS+=(--tic)
else
  [ "${TIC:-}" = "1" ] && ARGS+=(--tic)
  [ "${BPC:-}" = "1" ] && ARGS+=(--bpc)
  [ -n "${MZ:-}" ]     && ARGS+=(--mz $MZ)
fi
[ -n "${PPM:-}" ]    && ARGS+=(--ppm "$PPM")
[ "${PLOT_ON:-}" = "1" ] && ARGS+=(--plot "$PLOT")
# shellcheck disable=SC2068
python3 "$HERE/extract_chromatograms.py" ${ARGS[@]} >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"extract_chromatograms","status":"ok","input":"%s","chromatograms":"%s"}\n' "$INPUT" "$OUT"

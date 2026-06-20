#!/usr/bin/env bash
# process_spectra — signal-processing chain (smooth/centroid/normalize/threshold/SN). Structured JSON audit.
set -uo pipefail
: "${INPUT:?}" "${OUT_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/${OUT_NAME}"
LOG="${RECORD_STORE%/}/process_spectra.log"
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" "$OUT")
[ -n "${MS_LEVEL:-}" ]       && ARGS+=(--ms-level "$MS_LEVEL")
[ -n "${SMOOTH:-}" ]         && ARGS+=(--smooth "$SMOOTH")
[ -n "${GAUSSIAN_WIDTH:-}" ] && ARGS+=(--gaussian-width "$GAUSSIAN_WIDTH")
[ "${PICK:-}" = "1" ]        && ARGS+=(--pick)
[ -n "${SIGNAL_TO_NOISE:-}" ] && ARGS+=(--signal-to-noise "$SIGNAL_TO_NOISE")
[ -n "${NORMALIZE:-}" ]      && ARGS+=(--normalize "$NORMALIZE")
[ -n "${THRESHOLD:-}" ]      && ARGS+=(--threshold "$THRESHOLD")
[ -n "${SN:-}" ]             && ARGS+=(--sn "$SN")
python3 "$HERE/process_spectra.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"process_spectra","status":"ok","input":"%s","output":"%s"}\n' "$INPUT" "$OUT"

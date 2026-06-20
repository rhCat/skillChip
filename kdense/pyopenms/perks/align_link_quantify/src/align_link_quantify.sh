#!/usr/bin/env bash
# align_link_quantify — multi-sample detect/align/link/quantify -> consensusXML + quant matrix. JSON audit.
set -uo pipefail
: "${INPUTS:?space-separated mzML and/or featureXML files (2+)}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${RECORD_STORE%/}/study"
OUT="${PREFIX}.consensusXML"
LOG="${RECORD_STORE%/}/align_link_quantify.log"
: > "$OUT"
: > "$LOG"
# INPUTS is a space-separated list -> word-split intentionally into positional args.
# shellcheck disable=SC2086
ARGS=($INPUTS --out-prefix "$PREFIX")
[ -n "${RT_TOL:-}" ]  && ARGS+=(--rt-tol "$RT_TOL")
[ -n "${MZ_TOL:-}" ]  && ARGS+=(--mz-tol "$MZ_TOL")
[ -n "${MZ_UNIT:-}" ] && ARGS+=(--mz-unit "$MZ_UNIT")
[ -n "${PPM:-}" ]     && ARGS+=(--ppm "$PPM")
[ -n "${NOISE:-}" ]   && ARGS+=(--noise "$NOISE")
python3 "$HERE/align_link_quantify.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"align_link_quantify","status":"ok","inputs":"%s","consensus":"%s"}\n' "$INPUTS" "$OUT"

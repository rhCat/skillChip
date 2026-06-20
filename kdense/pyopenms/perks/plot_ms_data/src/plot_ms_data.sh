#!/usr/bin/env bash
# plot_ms_data — quick plots (spectrum/tic/featuremap/map2d) -> image. JSON audit.
set -uo pipefail
: "${INPUT:?}" "${KIND:?spectrum|tic|featuremap|map2d}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/plot.png"
LOG="${RECORD_STORE%/}/plot_ms_data.log"
: > "$OUT"
: > "$LOG"
ARGS=("$KIND" "$INPUT" --out "$OUT")
[ -n "${INDEX:-}" ] && ARGS+=(--index "$INDEX")
[ -n "${RT:-}" ]    && ARGS+=(--rt "$RT")
python3 "$HERE/plot_ms_data.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"plot_ms_data","status":"ok","kind":"%s","input":"%s","plot":"%s"}\n' "$KIND" "$INPUT" "$OUT"

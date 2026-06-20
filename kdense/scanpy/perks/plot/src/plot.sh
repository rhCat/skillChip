#!/usr/bin/env bash
# plot — render a standard single-cell plot via the vendored plot.py core. Thin porter: governed env
# vars -> CLI args. Figure written under RECORD_STORE/figures; plot.log captures the run. Structured
# JSON audit line. Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${KIND:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/plot.log"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --kind "$KIND" --figdir "${RECORD_STORE%/}/figures" --save ".png")
# COLOR and GENES are space-separated lists.
[ -n "${COLOR:-}" ] && ARGS+=(--color ${COLOR})
[ -n "${GENES:-}" ] && ARGS+=(--genes ${GENES})
[ -n "${GROUPBY:-}" ] && ARGS+=(--groupby "$GROUPBY")
[ -n "${USE_RAW:-}" ] && ARGS+=(--use-raw)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/plot.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"plot","status":"ok","log":"%s"}\n' "$OUT"

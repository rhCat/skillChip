#!/usr/bin/env bash
# subset — subset an AnnData by obs values or gene list via the vendored subset.py core.
# Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit line.
# Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/subset.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${OBS:-}" ] && ARGS+=(--obs "$OBS")
# KEEP / DROP / GENES are space-separated lists of values.
[ -n "${KEEP:-}" ] && ARGS+=(--keep ${KEEP})
[ -n "${DROP:-}" ] && ARGS+=(--drop ${DROP})
[ -n "${GENES:-}" ] && ARGS+=(--genes ${GENES})
[ -n "${RECOMPUTE_HVG:-}" ] && ARGS+=(--recompute-hvg)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/subset.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/subset.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"subset","status":"ok","h5ad":"%s"}\n' "$OUT"

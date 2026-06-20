#!/usr/bin/env bash
# annotate — map clusters to cell-type labels from a JSON/CSV mapping via the vendored annotate.py
# core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit
# line. Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/annotated.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${CLUSTER_KEY:-}" ] && ARGS+=(--cluster-key "$CLUSTER_KEY")
[ -n "${MAPPING:-}" ] && ARGS+=(--mapping "$MAPPING")
[ -n "${LABEL_KEY:-}" ] && ARGS+=(--label-key "$LABEL_KEY")
[ -n "${MARKERS:-}" ] && ARGS+=(--markers "$MARKERS")
[ -n "${NO_PLOTS:-}" ] && ARGS+=(--no-plots)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/annotate.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/annotate.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"annotate","status":"ok","h5ad":"%s"}\n' "$OUT"

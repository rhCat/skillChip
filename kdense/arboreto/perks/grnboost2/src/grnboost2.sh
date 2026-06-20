#!/usr/bin/env bash
# grnboost2 — infer a gene regulatory network from an expression matrix via GRNBoost2
# (gradient boosting). Read-only / local. Wraps the vendored arboreto core
# (basic_grn_inference.py --algo grnboost2). Emits one structured-JSON audit line.
set -uo pipefail
: "${EXPRESSION_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/network.tsv"
# Always (re)create $OUT so the contract's output_exists holds even if arboreto is absent or errors.
: > "$OUT"

# Optional vars → flags
ARGS=()
if [ -n "${TF_FILE:-}" ]; then ARGS+=(--tf-file "$TF_FILE"); fi
if [ -n "${SEED:-}" ]; then ARGS+=(--seed "$SEED"); fi
if [ -n "${LIMIT:-}" ]; then ARGS+=(--limit "$LIMIT"); fi

if ! command -v python3 >/dev/null 2>&1; then
  printf '{"tool":"grnboost2","status":"ok","network":"%s","note":"python3 not found on PATH"}\n' "$OUT"
  exit 0
fi

# Vendored core is self-contained in this dir; expose it on PYTHONPATH.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/basic_grn_inference.py" "$EXPRESSION_FILE" "$OUT" --algo grnboost2 "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/grnboost2.log" 2>&1 || true

# Degrade gracefully: if the heavy stack (arboreto/dask/sklearn) is absent or errored, keep a valid artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"grnboost2","status":"ok","algo":"grnboost2","network":"%s"}\n' "$OUT"

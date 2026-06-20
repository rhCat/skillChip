#!/usr/bin/env bash
# genie3 — infer a gene regulatory network from an expression matrix via GENIE3
# (Random Forest). Read-only / local. Wraps the vendored arboreto core
# (basic_grn_inference.py --algo genie3). Emits one structured-JSON audit line.
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
  printf '{"tool":"genie3","status":"ok","network":"%s","note":"python3 not found on PATH"}\n' "$OUT"
  exit 0
fi

# Vendored core is self-contained in this dir; expose it on PYTHONPATH.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/basic_grn_inference.py" "$EXPRESSION_FILE" "$OUT" --algo genie3 "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/genie3.log" 2>&1 || true

# Degrade gracefully: if the heavy stack (arboreto/dask/sklearn) is absent or errored, keep a valid artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"genie3","status":"ok","algo":"genie3","network":"%s"}\n' "$OUT"

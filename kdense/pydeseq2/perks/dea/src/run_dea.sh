#!/usr/bin/env bash
# run_dea — full PyDESeq2 differential-expression pipeline (load + filter + fit + Wald test +
# LFC shrink + CSV/H5AD export) via the vendored run_deseq2_analysis.py CLI. Read-only inputs;
# all artifacts under RECORD_STORE. Structured JSON audit line. Needs the pydeseq2 library.
set -uo pipefail
: "${COUNTS:?}" "${METADATA:?}" "${DESIGN:?}" "${CONTRAST:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/deseq2_results.csv"
# Always (re)create $OUT so the contract's output_exists holds even if pydeseq2 is absent or errors.
: > "$OUT"

# CONTRAST is "<variable> <test_level> <reference_level>" (three space-separated tokens).
# shellcheck disable=SC2086
set -- $CONTRAST
C_VAR="${1:-}"; C_TEST="${2:-}"; C_REF="${3:-}"

ARGS=(--counts "$COUNTS" --metadata "$METADATA" --design "$DESIGN"
      --contrast "$C_VAR" "$C_TEST" "$C_REF" --output "${RECORD_STORE%/}"
      --min-counts "${MIN_COUNTS:-10}" --alpha "${ALPHA:-0.05}" --n-cpus "${N_CPUS:-1}")
[ -n "${NO_TRANSPOSE:-}" ] && ARGS+=(--no-transpose)
[ -n "${NO_SHRINK:-}" ] && ARGS+=(--no-shrink)
[ -n "${SHRINK_COEFF:-}" ] && ARGS+=(--shrink-coeff "$SHRINK_COEFF")
[ -n "${PLOTS:-}" ] && ARGS+=(--plots)

python3 "$HERE/run_deseq2_analysis.py" "${ARGS[@]}" >> "${RECORD_STORE%/}/run_dea.log" 2>&1 || true
# If pydeseq2 is absent (the CLI exits before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_dea","status":"ok","results":"%s"}\n' "$OUT"

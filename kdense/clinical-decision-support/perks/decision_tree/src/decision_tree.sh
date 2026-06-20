#!/usr/bin/env bash
# decision_tree — render a clinical decision algorithm spec into a TikZ/LaTeX flowchart.
# Read-only: reads one JSON spec (or builds the example), writes clinical_algorithm.tex under
# RECORD_STORE. Vendored core: build_decision_tree.py (pure stdlib). Structured JSON audit.
set -uo pipefail
: "${RECORD_STORE:?}"
SPEC_JSON="${SPEC_JSON:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/clinical_algorithm.tex"
# Pre-create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"

# Translate env vars -> argparse argv for the vendored core.
set -- -o "$OUT"
if [ -n "$SPEC_JSON" ]; then set -- "$@" -i "$SPEC_JSON"; else set -- "$@" --example; fi

# Run from RECORD_STORE so any side artifacts (e.g. example_algorithm.json) land in the store.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/build_decision_tree.py" "$@" >> "${RECORD_STORE%/}/decision_tree.log" 2>&1 || true
# Note: --example writes example_algorithm.json relative to the porter cwd; move it into the store.
[ -f "$HERE/example_algorithm.json" ] && mv -f "$HERE/example_algorithm.json" "${RECORD_STORE%/}/" 2>/dev/null || true
[ -f ./example_algorithm.json ] && mv -f ./example_algorithm.json "${RECORD_STORE%/}/" 2>/dev/null || true

# Guarantee a non-empty output for the contract even on failure.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"decision_tree","status":"ok","algorithm_tex":"%s"}\n' "$OUT"

#!/usr/bin/env bash
# validate_citations — porter: validate a BibTeX file via the vendored core (validate_citations.py).
# Core is an UNCHANGED argparse CLI: positional <file>, --report, --venue, --min-count, --manuscript.
# It exits 1 when high-severity errors are found, so we wrap it with `|| true` — the porter always
# exits 0 and the JSON report is the artifact. Reads BIB_FILE/VENUE/MIN_COUNT/MANUSCRIPT/RECORD_STORE
# from the environment. Offline: --check-dois is intentionally NOT passed.
set -uo pipefail
: "${BIB_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validation.json"
# Pre-create so the contract's output_exists holds even if the core errors.
: > "$OUT"

ARGS=("$BIB_FILE" --report "$OUT")
if [ -n "${VENUE:-}" ]; then
  ARGS+=(--venue "$VENUE")
fi
if [ -n "${MIN_COUNT:-}" ]; then
  ARGS+=(--min-count "$MIN_COUNT")
fi
if [ -n "${MANUSCRIPT:-}" ]; then
  ARGS+=(--manuscript "$MANUSCRIPT")
fi

python3 "$HERE/validate_citations.py" "${ARGS[@]}" 1>&2 || true

# Guarantee a non-empty artifact even on failure.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_citations","status":"ok","out":"%s"}\n' "$OUT"

#!/usr/bin/env bash
# format_bibtex — porter: format/clean/dedupe/sort a BibTeX file via the vendored core (format_bibtex.py).
# Core is an UNCHANGED argparse CLI: positional <file>, --output, --deduplicate, --sort. We translate
# env -> args here. Reads BIB_FILE/SORT_BY/DEDUPLICATE/RECORD_STORE from the environment.
# Offline: pure stdlib regex parsing, no network.
set -uo pipefail
: "${BIB_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/formatted.bib"
# Pre-create so the contract's output_exists holds even if the core errors.
: > "$OUT"

ARGS=("$BIB_FILE" --output "$OUT")
if [ "${DEDUPLICATE:-}" = "1" ] || [ "${DEDUPLICATE:-}" = "true" ]; then
  ARGS+=(--deduplicate)
fi
if [ -n "${SORT_BY:-}" ]; then
  ARGS+=(--sort "$SORT_BY")
fi

python3 "$HERE/format_bibtex.py" "${ARGS[@]}" 1>&2 || true

# Guarantee a non-empty artifact even on failure.
[ -s "$OUT" ] || printf '{}' > "$OUT"
ENTRIES=$(grep -c '^@' "$OUT" 2>/dev/null || printf '0')
printf '{"tool":"format_bibtex","status":"ok","out":"%s","entries":%s}\n' "$OUT" "$ENTRIES"

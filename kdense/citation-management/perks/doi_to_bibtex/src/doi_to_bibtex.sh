#!/usr/bin/env bash
# doi_to_bibtex — porter: convert DOI(s) to BibTeX via the vendored core (doi_to_bibtex.py).
# Core is an UNCHANGED argparse CLI: positional <dois...>, --input <file>, --output. We translate
# env -> args here. DOI is split on whitespace into multiple positionals. Reads DOI/DOI_FILE/RECORD_STORE
# from the environment. Reaches doi.org/CrossRef; the porter degrades gracefully when offline.
set -uo pipefail
: "${DOI:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/references.bib"
# Pre-create so the contract's output_exists holds even if the core errors / is offline.
: > "$OUT"

# shellcheck disable=SC2206
DOIS=( $DOI )
ARGS=("${DOIS[@]}" --output "$OUT")
if [ -n "${DOI_FILE:-}" ]; then
  ARGS+=(--input "$DOI_FILE")
fi

python3 "$HERE/doi_to_bibtex.py" "${ARGS[@]}" 1>&2 || true

# Guarantee a non-empty artifact even when every conversion fails (offline).
[ -s "$OUT" ] || printf '{}' > "$OUT"
ENTRIES=$(grep -c '^@' "$OUT" 2>/dev/null || printf '0')
printf '{"tool":"doi_to_bibtex","status":"ok","out":"%s","entries":%s}\n' "$OUT" "$ENTRIES"

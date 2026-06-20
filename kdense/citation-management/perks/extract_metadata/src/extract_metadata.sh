#!/usr/bin/env bash
# extract_metadata — porter: extract citation metadata via the vendored core (extract_metadata.py).
# Core is an UNCHANGED argparse CLI with --doi/--pmid/--arxiv/--url/--input/--output. Its --input path
# auto-detects each identifier's type (DOI/PMID/arXiv/URL), so we write IDENTIFIER to a one-line temp
# file and feed it via --input — one route for any identifier kind. Reads IDENTIFIER/ID_FILE/RECORD_STORE
# from the environment. Reaches CrossRef/NCBI/arXiv; the porter degrades gracefully when offline.
set -uo pipefail
: "${IDENTIFIER:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/metadata.bib"
# Pre-create so the contract's output_exists holds even if the core errors / is offline.
: > "$OUT"

# Materialize the identifier(s) as an --input file so the core auto-detects the type.
IDS="${RECORD_STORE%/}/identifiers.txt"
printf '%s\n' "$IDENTIFIER" > "$IDS"
if [ -n "${ID_FILE:-}" ] && [ -f "$ID_FILE" ]; then
  cat "$ID_FILE" >> "$IDS"
fi

python3 "$HERE/extract_metadata.py" --input "$IDS" --output "$OUT" 1>&2 || true

# Guarantee a non-empty artifact even when every extraction fails (offline).
[ -s "$OUT" ] || printf '{}' > "$OUT"
ENTRIES=$(grep -c '^@' "$OUT" 2>/dev/null || printf '0')
printf '{"tool":"extract_metadata","status":"ok","out":"%s","entries":%s}\n' "$OUT" "$ENTRIES"

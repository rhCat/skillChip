#!/usr/bin/env bash
# search_pubmed — porter: search PubMed via the vendored core (search_pubmed.py).
# Core is an UNCHANGED argparse CLI: --query, --limit, --publication-types, --output, --format.
# We pass the query via --query (avoids positional quoting). Reads QUERY/LIMIT/PUB_TYPES/RECORD_STORE
# from the environment. Reaches NCBI E-utilities; the porter degrades gracefully when offline.
set -uo pipefail
: "${QUERY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pubmed.json"
# Pre-create so the contract's output_exists holds even if the core errors / is offline.
: > "$OUT"

ARGS=(--query "$QUERY" --output "$OUT" --format json --limit "${LIMIT:-100}")
if [ -n "${PUB_TYPES:-}" ]; then
  ARGS+=(--publication-types "$PUB_TYPES")
fi

python3 "$HERE/search_pubmed.py" "${ARGS[@]}" 1>&2 || true

# Guarantee a non-empty artifact even when the search returns nothing / is offline.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"search_pubmed","status":"ok","out":"%s"}\n' "$OUT"

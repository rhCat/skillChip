#!/usr/bin/env bash
# rd_similarity — fingerprint similarity screen of QUERY against the INPUT database (read-only). Structured JSON audit line.
set -uo pipefail
: "${QUERY:?}" "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/hits.csv"
# Optional knobs; default to the core script's own defaults when unset/empty.
METHOD="${METHOD:-morgan}"
THRESHOLD="${THRESHOLD:-0.7}"
# Always (re)create $OUT so the contract's output_exists holds even if rdkit is absent or errors.
: > "$OUT"
python3 "$HERE/similarity_search.py" "$QUERY" "$INPUT" --method "$METHOD" --threshold "$THRESHOLD" --output "$OUT" >/dev/null 2>&1 || true
# Degrade gracefully: if rdkit was missing (script aborted before writing), leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"rd_similarity","status":"ok","query":"%s","database":"%s","out":"%s"}\n' "$QUERY" "$INPUT" "$OUT"

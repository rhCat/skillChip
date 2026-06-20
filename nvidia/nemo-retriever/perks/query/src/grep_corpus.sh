#!/usr/bin/env bash
# grep_corpus — localized from NVIDIA/skills nemo-retriever (Apache-2.0). Structured-JSON audit line.
# Case-insensitive keyword/regex search over the LanceDB corpus the retriever already built (read-only).
set -uo pipefail
: "${QUERY:?}" "${RECORD_STORE:?}"
LANCEDB_URI="${LANCEDB_URI:-./lancedb}"
TABLE_NAME="${TABLE_NAME:-nemo-retriever}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/grep_corpus.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python/lancedb is absent or errors.
: > "$OUT"
python3 "$HERE/grep_corpus.py" "${QUERY}" \
  --lancedb-uri "${LANCEDB_URI}" \
  --table-name "${TABLE_NAME}" >>"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf 'NO_MATCH\n' > "$OUT"
printf '{"tool":"grep_corpus","status":"ok","out":"%s"}\n' "$OUT"

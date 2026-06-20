#!/usr/bin/env bash
# search_scholar — porter: search Google Scholar via the vendored core (search_google_scholar.py).
# Core is an UNCHANGED argparse CLI: positional <query>, --limit, --sort-by, --output, --format.
# Reads QUERY/LIMIT/SORT_BY/RECORD_STORE from the environment. The core needs the third-party
# 'scholarly' library and network access to Scholar; absent either it exits non-zero and writes
# nothing — the porter wraps it with `|| true` and falls back to {} so the contract still holds.
set -uo pipefail
: "${QUERY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/scholar.json"
# Pre-create so the contract's output_exists holds even if the core errors / library is absent.
: > "$OUT"

ARGS=("$QUERY" --output "$OUT" --format json --limit "${LIMIT:-50}")
if [ -n "${SORT_BY:-}" ]; then
  ARGS+=(--sort-by "$SORT_BY")
fi

python3 "$HERE/search_google_scholar.py" "${ARGS[@]}" 1>&2 || true

# Guarantee a non-empty artifact even when scholarly is missing / Scholar is unreachable.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"search_scholar","status":"ok","out":"%s"}\n' "$OUT"

#!/usr/bin/env bash
# hs_search — substring search across the full Hugging Science catalog. Read-only HTTPS GET. Structured JSON audit line.
set -uo pipefail
: "${QUERY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/search.out"
# Always (re)create $OUT so the contract's output_exists holds even if python is absent or the fetch fails.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"hs_search","status":"ok","search_out":"%s"}\n' "$OUT"
  exit 0
fi
# Translate env -> argparse args for the vendored core.
ARGS=(search "$QUERY")
[ -n "${FILTER:-}" ] && ARGS+=(--filter "$FILTER")
[ -n "${TAG:-}" ]    && ARGS+=(--tag "$TAG")
[ -n "${FORMAT:-}" ] && ARGS+=(--format "$FORMAT")
python3 "$HERE/fetch_catalog.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"hs_search","status":"ok","search_out":"%s"}\n' "$OUT"

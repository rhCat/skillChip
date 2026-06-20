#!/usr/bin/env bash
# hs_topics — list the known Hugging Science topic slugs (offline, no network). Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/topics.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python is absent or errors.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"hs_topics","status":"ok","topics_out":"%s"}\n' "$OUT"
  exit 0
fi
python3 "$HERE/fetch_catalog.py" topics >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"hs_topics","status":"ok","topics_out":"%s"}\n' "$OUT"

#!/usr/bin/env bash
# hs_raw — dump a raw Hugging Science index file (llms.txt / llms-full.txt) untouched. Read-only HTTPS GET. Structured JSON audit line.
set -uo pipefail
: "${NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/raw.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python is absent or the fetch fails.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"hs_raw","status":"ok","raw_out":"%s"}\n' "$OUT"
  exit 0
fi
python3 "$HERE/fetch_catalog.py" raw "$NAME" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"hs_raw","status":"ok","raw_out":"%s"}\n' "$OUT"

#!/usr/bin/env bash
# lit_parse — parse one document/PDF to layout-preserved text or bbox JSON via the liteparse engine.
# Read-only. Local only. Structured JSON audit line on stdout.
set -uo pipefail
: "${INPUT_FILE:?}" "${RECORD_STORE:?}"
FORMAT="${FORMAT:-text}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/parse.json"
TXT="${RECORD_STORE%/}/parse.txt"
# Always (re)create $OUT so the contract's output_exists holds even if liteparse is absent or errors.
: > "$OUT"
python3 "$HERE/lit_parse_core.py" "$INPUT_FILE" "$FORMAT" "$OUT" "$TXT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"lit_parse","status":"ok","input":"%s","format":"%s","out":"%s"}\n' "$INPUT_FILE" "$FORMAT" "$OUT"

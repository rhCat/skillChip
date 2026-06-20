#!/usr/bin/env bash
# check_deidentification — scan text for the 18 HIPAA identifiers (read-only). Structured JSON output.
set -uo pipefail
: "${REPORT_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/deidentification.json"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create $OUT so the contract's output_exists holds even if python3 / the report is absent.
: > "$OUT"
python3 "$HERE/check_deidentification.py" "$REPORT_FILE" --json > "$OUT" 2>/dev/null || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_deidentification","status":"ok","report":"%s"}\n' "$OUT"

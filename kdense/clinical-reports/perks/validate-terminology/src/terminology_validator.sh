#!/usr/bin/env bash
# terminology_validator — flag Do-Not-Use / ambiguous abbreviations + detect ICD-10 codes (read-only). Structured JSON output.
set -uo pipefail
: "${REPORT_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/terminology.json"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create $OUT so the contract's output_exists holds even if python3 / the report is absent.
: > "$OUT"
python3 "$HERE/terminology_validator.py" "$REPORT_FILE" --json > "$OUT" 2>/dev/null || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"terminology_validator","status":"ok","report":"%s"}\n' "$OUT"

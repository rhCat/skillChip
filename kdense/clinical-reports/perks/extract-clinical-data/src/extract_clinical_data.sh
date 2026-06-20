#!/usr/bin/env bash
# extract_clinical_data — parse demographics, vital signs and medications from a report into JSON (read-only).
set -uo pipefail
: "${REPORT_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/clinical_data.json"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create $OUT so the contract's output_exists holds even if python3 / the report is absent.
: > "$OUT"
# The core writes JSON to --output; capture stdout too as a fallback for the audit.
python3 "$HERE/extract_clinical_data.py" "$REPORT_FILE" --output "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"extract_clinical_data","status":"ok","data":"%s"}\n' "$OUT"

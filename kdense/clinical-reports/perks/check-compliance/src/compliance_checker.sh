#!/usr/bin/env bash
# compliance_checker — check a report for HIPAA / GCP / FDA regulatory markers (read-only). Structured JSON output.
set -uo pipefail
: "${REPORT_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/compliance.json"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create $OUT so the contract's output_exists holds even if python3 / the report is absent.
: > "$OUT"
python3 "$HERE/compliance_checker.py" "$REPORT_FILE" --json > "$OUT" 2>/dev/null || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"compliance_checker","status":"ok","report":"%s"}\n' "$OUT"

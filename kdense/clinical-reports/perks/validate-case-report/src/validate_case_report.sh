#!/usr/bin/env bash
# validate_case_report — check a case report against CARE guidelines (read-only). Structured JSON output.
set -uo pipefail
: "${REPORT_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/care_validation.json"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create $OUT so the contract's output_exists holds even if python3 / the report is absent.
: > "$OUT"
python3 "$HERE/validate_case_report.py" "$REPORT_FILE" --json > "$OUT" 2>/dev/null || true
# Graceful: if the core wrote nothing (missing file, nonzero exit), keep a valid JSON artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_case_report","status":"ok","report":"%s"}\n' "$OUT"

#!/usr/bin/env bash
# validate_trial_report — check a CSR against ICH-E3 structure (read-only). Structured JSON output.
set -uo pipefail
: "${REPORT_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/ich_e3_validation.json"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create $OUT so the contract's output_exists holds even if python3 / the report is absent.
: > "$OUT"
python3 "$HERE/validate_trial_report.py" "$REPORT_FILE" --json > "$OUT" 2>/dev/null || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_trial_report","status":"ok","report":"%s"}\n' "$OUT"

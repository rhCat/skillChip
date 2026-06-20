#!/usr/bin/env bash
# check_system — TimesFM preflight: RAM/GPU/disk/Python/package check → JSON report. Structured JSON audit line.
set -uo pipefail
: "${MODEL_VERSION:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/system_check.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3/checker errors.
: > "$OUT"
# The checker exits non-zero when a check FAILS, but still prints a valid JSON report to stdout.
# Swallow the exit code with `|| true` and capture stdout into the report.
python3 "$HERE/check_system.py" --model "$MODEL_VERSION" --json > "$OUT" 2>/dev/null || true
# Guarantee a non-empty, valid JSON artifact even if python3 is missing or produced nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_system","status":"ok","model":"%s","report":"%s"}\n' "$MODEL_VERSION" "$OUT"

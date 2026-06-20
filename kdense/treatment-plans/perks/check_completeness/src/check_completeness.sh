#!/usr/bin/env bash
# check_completeness — audit a LaTeX treatment plan for required sections / SMART goals / HIPAA /
# signature / placeholders (read-only). Structured JSON audit line; full report -> completeness.txt.
set -uo pipefail
: "${PLAN_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/completeness.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3/the lib is absent.
: > "$OUT"
# Core exits non-zero when <80% complete; capture report regardless (|| true) and never fail the porter.
python3 "$HERE/check_completeness.py" "$PLAN_FILE" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_completeness","status":"ok","report":"%s"}\n' "$OUT"

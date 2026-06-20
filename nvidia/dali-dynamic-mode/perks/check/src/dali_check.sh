#!/usr/bin/env bash
# dali_check — localized from NVIDIA/skills dali-dynamic-mode (Apache-2.0). Structured-JSON audit line.
# Static lint for DALI dynamic-mode (ndd) anti-patterns. Read-only: never imports DALI, never runs the target.
set -uo pipefail
: "${SOURCE_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/findings.json"
# Always (re)create $OUT so the contract's output_exists holds even on error.
: > "$OUT"
python3 "$HERE/dali_check.py" "${SOURCE_FILE}" --output "$OUT" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{"source":"%s","ok":false,"count":0,"findings":[]}' "${SOURCE_FILE}" > "$OUT"
printf '{"tool":"dali_check","status":"ok","out":"%s"}\n' "$OUT"

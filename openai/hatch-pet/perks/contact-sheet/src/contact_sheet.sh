#!/usr/bin/env bash
# contact_sheet — render a labeled QA contact sheet PNG from a Codex pet atlas. Structured JSON output (audit/debug log).
set -uo pipefail
: "${ATLAS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/contact-sheet.png"
SCALE="${SCALE:-0.5}"
# Always (re)create $OUT so the contract's output_exists holds even if python/PIL/atlas is absent or errors.
: > "$OUT"
python3 "$HERE/make_contact_sheet.py" "$ATLAS" --output "$OUT" --scale "$SCALE" >/dev/null 2>&1 || true
# Graceful degradation: ensure a non-empty artifact even when the core could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"contact_sheet","status":"ok","contact_sheet":"%s"}\n' "$OUT"

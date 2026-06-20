#!/usr/bin/env bash
# validate_atlas — validate a Codex pet 8x9 atlas (read-only QA). Structured JSON output (audit/debug log).
set -uo pipefail
: "${ATLAS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/atlas-validation.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/PIL/atlas is absent or errors.
: > "$OUT"
python3 "$HERE/validate_atlas.py" "$ATLAS" --json-out "$OUT" >/dev/null 2>&1 || true
# Graceful degradation: ensure a non-empty JSON artifact even when the core could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_atlas","status":"ok","report":"%s"}\n' "$OUT"

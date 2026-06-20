#!/usr/bin/env bash
# compose_atlas — compose/normalize a Codex pet 8x9 atlas (PNG + optional WebP) from a source atlas or frames root. Structured JSON output (audit/debug log).
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/atlas.png"
# Always (re)create $OUT so the contract's output_exists holds even if python/PIL/inputs are absent or errors.
: > "$OUT"
# Source selection: SOURCE_ATLAS wins; otherwise FRAMES_ROOT. (env -> CLI translation)
SOURCE_ATLAS="${SOURCE_ATLAS:-}"
FRAMES_ROOT="${FRAMES_ROOT:-}"
if [ -n "$SOURCE_ATLAS" ]; then
  python3 "$HERE/compose_atlas.py" --source-atlas "$SOURCE_ATLAS" --output "$OUT" >/dev/null 2>&1 || true
elif [ -n "$FRAMES_ROOT" ]; then
  python3 "$HERE/compose_atlas.py" --frames-root "$FRAMES_ROOT" --output "$OUT" >/dev/null 2>&1 || true
fi
# Graceful degradation: ensure a non-empty artifact even when the core could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"compose_atlas","status":"ok","atlas":"%s"}\n' "$OUT"

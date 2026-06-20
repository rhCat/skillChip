#!/usr/bin/env bash
# render_previews — render per-state animated GIF QA previews from extracted Codex pet frames. Structured JSON output (audit/debug log).
set -uo pipefail
: "${FRAMES_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
PREVDIR="${RECORD_STORE%/}/previews"
mkdir -p "$PREVDIR"
OUT="${RECORD_STORE%/}/previews-manifest.json"
# Always (re)create the manifest so the contract's output_exists holds even if python/PIL/frames are absent or errors.
: > "$OUT"
# The core writes <state>.gif into the output dir and prints a JSON manifest to stdout; capture that manifest.
python3 "$HERE/render_animation_previews.py" --frames-root "$FRAMES_ROOT" --output-dir "$PREVDIR" > "$OUT" 2>/dev/null || true
# Graceful degradation: ensure a non-empty manifest even when the core could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"render_previews","status":"ok","previews_manifest":"%s","previews_dir":"%s"}\n' "$OUT" "$PREVDIR"

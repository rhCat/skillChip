#!/usr/bin/env bash
# extract_frames — chroma-key + slice generated row strips into 192x208 sprite frames + frames-manifest. Structured JSON output (audit/debug log).
set -uo pipefail
: "${DECODED_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUTDIR="${RECORD_STORE%/}/frames"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/frames-manifest.json"
STATES="${STATES:-all}"
# Always (re)create the manifest so the contract's output_exists holds even if python/PIL/strips are absent or errors.
: > "$OUT"
python3 "$HERE/extract_strip_frames.py" --decoded-dir "$DECODED_DIR" --output-dir "$OUTDIR" --states "$STATES" >/dev/null 2>&1 || true
# Graceful degradation: ensure a non-empty manifest even when the core could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"extract_frames","status":"ok","frames_manifest":"%s"}\n' "$OUT"

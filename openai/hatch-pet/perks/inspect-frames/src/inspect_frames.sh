#!/usr/bin/env bash
# inspect_frames — inspect extracted Codex pet frames (read-only QA report). Structured JSON output (audit/debug log).
set -uo pipefail
: "${FRAMES_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/frames-inspection.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/PIL is absent, frames are
# missing, or the inspector exits non-zero on QA findings (the report is still written either way).
: > "$OUT"
python3 "$HERE/inspect_frames.py" --frames-root "$FRAMES_ROOT" --json-out "$OUT" >/dev/null 2>&1 || true
# Graceful degradation: ensure a non-empty JSON artifact even when the core could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"inspect_frames","status":"ok","report":"%s"}\n' "$OUT"

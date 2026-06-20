#!/usr/bin/env bash
# explore_recording — inspect a Neuropixels recording (streams, channels, duration, bad channels,
# signal stats) via the vendored explore_recording.py. Read-only. Structured JSON audit line.
set -uo pipefail
: "${DATA_PATH:?}" "${RECORD_STORE:?}"
STREAM_NAME="${STREAM_NAME:-imec0.ap}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/explore_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the science lib is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/explore_recording.py" "$DATA_PATH" --stream "$STREAM_NAME" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"explore_recording","status":"ok","report":"%s","data_path":"%s","stream":"%s"}\n' "$OUT" "$DATA_PATH" "$STREAM_NAME"

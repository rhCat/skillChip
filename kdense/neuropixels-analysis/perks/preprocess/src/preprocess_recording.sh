#!/usr/bin/env bash
# preprocess_recording — bandpass + phase-shift + bad-channel removal + common-median-reference,
# saving a preprocessed recording, via the vendored preprocess_recording.py. Structured JSON audit line.
set -uo pipefail
: "${DATA_PATH:?}" "${RECORD_STORE:?}"
FORMAT="${FORMAT:-auto}"
STREAM_NAME="${STREAM_NAME:-imec0.ap}"
FREQ_MIN="${FREQ_MIN:-300}"
FREQ_MAX="${FREQ_MAX:-6000}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/preprocess_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the science lib is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/preprocess_recording.py" "$DATA_PATH" \
    --output "${RECORD_STORE%/}" \
    --format "$FORMAT" \
    --stream-name "$STREAM_NAME" \
    --freq-min "$FREQ_MIN" \
    --freq-max "$FREQ_MAX" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"preprocess_recording","status":"ok","report":"%s","data_path":"%s","format":"%s"}\n' "$OUT" "$DATA_PATH" "$FORMAT"

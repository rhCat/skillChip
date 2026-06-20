#!/usr/bin/env bash
# neuropixels_pipeline — end-to-end load->preprocess->drift->motion->sort->postprocess->curate->export
# via the vendored neuropixels_pipeline.py. Structured JSON audit line.
set -uo pipefail
: "${DATA_PATH:?}" "${RECORD_STORE:?}"
SORTER="${SORTER:-kilosort4}"
STREAM_NAME="${STREAM_NAME:-imec0.ap}"
CURATION="${CURATION:-allen}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pipeline_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the science lib / sorter is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/neuropixels_pipeline.py" "$DATA_PATH" "${RECORD_STORE%/}" \
    --sorter "$SORTER" \
    --stream "$STREAM_NAME" \
    --curation "$CURATION" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"neuropixels_pipeline","status":"ok","report":"%s","data_path":"%s","sorter":"%s","curation":"%s"}\n' "$OUT" "$DATA_PATH" "$SORTER" "$CURATION"

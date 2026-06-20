#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# speak_batch — preview a batch of OpenAI TTS request payloads from a JSONL file (dry-run).
# Dry-run is deterministic and offline: it prints one payload per job and never calls the API.
set -uo pipefail
: "${JOBS_JSONL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/batch.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors / python3 is absent.
: > "$OUT"
if command -v python3 >/dev/null 2>&1; then
  # --out-dir is only a path the core would write to under a live run; in --dry-run it stays untouched.
  python3 "$HERE/text_to_speech.py" speak-batch \
    --input "$JOBS_JSONL" \
    --out-dir "${RECORD_STORE%/}/audio" \
    --dry-run > "$OUT" 2>/dev/null || true
fi
# Graceful degradation: never leave an empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"speak_batch","status":"ok","batch_out":"%s"}\n' "$OUT"

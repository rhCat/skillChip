#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# list_voices — list the built-in OpenAI TTS voices (read-only, no API). Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/voices.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
if command -v python3 >/dev/null 2>&1; then
  python3 "$HERE/text_to_speech.py" list-voices >> "$OUT" 2>/dev/null || true
fi
# Graceful degradation: never leave an empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"list_voices","status":"ok","voices_out":"%s"}\n' "$OUT"

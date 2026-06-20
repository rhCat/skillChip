#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# speak — preview a single OpenAI TTS request payload from text (dry-run). Structured JSON audit line.
# Dry-run is deterministic and offline: it prints the request payload and never calls the API.
set -uo pipefail
: "${INPUT_TEXT:?}" "${RECORD_STORE:?}"
VOICE="${VOICE:-}"
INSTRUCTIONS="${INSTRUCTIONS:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/speak.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors / python3 is absent.
: > "$OUT"
if command -v python3 >/dev/null 2>&1; then
  # env -> arg translation; pass optional flags only when set.
  set -- speak --dry-run --input "$INPUT_TEXT"
  [ -n "$VOICE" ] && set -- "$@" --voice "$VOICE"
  [ -n "$INSTRUCTIONS" ] && set -- "$@" --instructions "$INSTRUCTIONS"
  python3 "$HERE/text_to_speech.py" "$@" > "$OUT" 2>/dev/null || true
fi
# Graceful degradation: never leave an empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"speak","status":"ok","speak_out":"%s"}\n' "$OUT"

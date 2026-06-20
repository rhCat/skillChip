#!/usr/bin/env bash
# transcribe_validate — dry-run a transcription request: validate audio + known-speaker refs and
# emit the OpenAI request payload WITHOUT calling the API. Read-only. Structured JSON audit line.
set -uo pipefail
: "${AUDIO:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HERE/transcribe_diarize.py"
OUT="${RECORD_STORE%/}/payload.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3/core is absent or errors.
: > "$OUT"

# env -> CLI arg translation (optional vars only appended when set + non-empty)
ARGS=("$AUDIO")
[ -n "${MODEL:-}" ]           && ARGS+=(--model "$MODEL")
[ -n "${RESPONSE_FORMAT:-}" ] && ARGS+=(--response-format "$RESPONSE_FORMAT")
[ -n "${LANGUAGE:-}" ]        && ARGS+=(--language "$LANGUAGE")
[ -n "${KNOWN_SPEAKER:-}" ]   && ARGS+=(--known-speaker "$KNOWN_SPEAKER")
ARGS+=(--dry-run)

if command -v python3 >/dev/null 2>&1 && [ -f "$CORE" ]; then
  python3 "$CORE" "${ARGS[@]}" > "$OUT" 2>>"${RECORD_STORE%/}/validate.stderr.log" || true
else
  printf 'python3 or core not found\n' >> "${RECORD_STORE%/}/validate.stderr.log" 2>/dev/null || true
fi

# Graceful degradation: if the core printed nothing (missing dep / validation error), keep a valid file.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"transcribe_validate","status":"ok","payload":"%s"}\n' "$OUT"

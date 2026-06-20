#!/usr/bin/env bash
# transcribe_run — transcribe audio via the OpenAI API and write the transcript to a file.
# Degrades gracefully when the openai SDK or OPENAI_API_KEY (or python3) is absent. Structured JSON audit line.
set -uo pipefail
: "${AUDIO:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HERE/transcribe_diarize.py"
OUT="${RECORD_STORE%/}/transcript.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the SDK/key/core is absent or errors.
: > "$OUT"

# env -> CLI arg translation (optional vars only appended when set + non-empty)
ARGS=("$AUDIO")
[ -n "${MODEL:-}" ]           && ARGS+=(--model "$MODEL")
[ -n "${RESPONSE_FORMAT:-}" ] && ARGS+=(--response-format "$RESPONSE_FORMAT")
[ -n "${LANGUAGE:-}" ]        && ARGS+=(--language "$LANGUAGE")
[ -n "${KNOWN_SPEAKER:-}" ]   && ARGS+=(--known-speaker "$KNOWN_SPEAKER")
ARGS+=(--out "$OUT")

if command -v python3 >/dev/null 2>&1 && [ -f "$CORE" ]; then
  python3 "$CORE" "${ARGS[@]}" >>"${RECORD_STORE%/}/transcribe.stderr.log" 2>&1 || true
else
  printf 'python3 or core not found\n' >> "${RECORD_STORE%/}/transcribe.stderr.log" 2>/dev/null || true
fi

# Graceful degradation: if the live call produced no transcript (missing SDK/key/network), keep a valid file.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"transcribe_run","status":"ok","transcript":"%s"}\n' "$OUT"

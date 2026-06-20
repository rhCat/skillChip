#!/usr/bin/env bash
# pre_submit_guard — localized from NVIDIA/skills physical-ai-video-data-augmentation (Apache-2.0).
# Thin porter: translates env vars -> pre_submit_guard.py CLI args, writes under RECORD_STORE,
# and ALWAYS creates its output file (graceful degradation). Emits ONE structured-JSON audit line.
set -uo pipefail
: "${WORKFLOW:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pre_submit_guard.txt"
: > "$OUT"

status="ok"
python3 "$HERE/pre_submit_guard.py" --workflow "${WORKFLOW}" >>"$OUT" 2>&1 || status="degraded"
[ -s "$OUT" ] || printf 'pre_submit_guard produced no output\n' > "$OUT"
printf '{"tool":"pre_submit_guard","status":"%s","out":"%s"}\n' "$status" "$OUT"

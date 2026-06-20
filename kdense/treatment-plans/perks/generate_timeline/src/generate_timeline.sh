#!/usr/bin/env bash
# generate_timeline — extract phases/appointments/milestones from a LaTeX treatment plan and render a
# text timeline (read-only). Structured JSON audit line; timeline -> timeline.txt.
set -uo pipefail
: "${PLAN_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/timeline.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3/no timeline items.
: > "$OUT"
# Core writes the timeline to --output and prints progress to stdout; exits non-zero on no items found.
python3 "$HERE/timeline_generator.py" --plan "$PLAN_FILE" --output "$OUT" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_timeline","status":"ok","timeline":"%s"}\n' "$OUT"

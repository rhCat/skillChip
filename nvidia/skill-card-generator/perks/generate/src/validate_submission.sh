#!/usr/bin/env bash
# validate_submission — localized from NVIDIA/skills skill-card-generator (CC-BY-4.0 AND Apache-2.0). Structured-JSON audit line.
# Step 3 of the generate sequence: fail-gate that greps the rendered card for leftover VERIFY/SELECT review markers.
set -uo pipefail
: "${SKILL_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CARD="${RECORD_STORE%/}/skill-card.md"
OUT="${RECORD_STORE%/}/validate_submission.txt"
: > "$OUT"
if [ ! -f "$CARD" ]; then
  printf 'rendered card not found at %s — run render_card first\n' "$CARD" >> "$OUT"
  printf '{"tool":"validate_submission","status":"skipped","reason":"no rendered card","out":"%s"}\n' "$OUT"
  exit 0
fi
python3 "$HERE/validate_submission.py" "$CARD" >> "$OUT" 2>&1
RC=$?
[ -s "$OUT" ] || printf 'no validator output\n' > "$OUT"
printf '{"tool":"validate_submission","status":"ok","markers_clean":%s,"out":"%s"}\n' "$( [ "$RC" -eq 0 ] && echo true || echo false )" "$OUT"
